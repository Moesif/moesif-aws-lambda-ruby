require "moesif_api"
require "json"
require "time"
require "base64"
require "zlib"
require "stringio"

require_relative "./update_user.rb"
require_relative "./update_company.rb"
require_relative "./moesif_helpers.rb"
require_relative "./lambda_utils.rb"

module Moesif
  class MoesifAwsMiddleware
    def initialize(handler, options = {})
      @handler = handler
      if not options["application_id"]
        raise "application_id required for Moesif Middleware"
      end
      @api_client = MoesifApi::MoesifAPIClient.new(options["application_id"])
      @api_controller = @api_client.api

      @api_version = options["api_version"]
      @identify_user = options["identify_user"]
      @identify_company = options["identify_company"]
      @get_metadata = options["get_metadata"]
      @identify_session = options["identify_session"]
      @mask_data = options["mask_data"]
      @skip = options["skip"]
      @debug = options["debug"]
      @moesif_helpers = MoesifHelpers.new(@debug)
      @disable_transaction_id = options["disable_transaction_id"] || false
      @log_body = options.fetch("log_body", true)
      @event_response_config_etag = nil
    end

    def update_user(user_profile)
      UserHelper.new.update_user(@api_controller, @debug, user_profile)
    end

    def update_users_batch(user_profiles)
      UserHelper.new.update_users_batch(@api_controller, @debug, user_profiles)
    end

    def update_company(company_profile)
      CompanyHelper.new.update_company(@api_controller, @debug, company_profile)
    end

    def update_companies_batch(company_profiles)
      CompanyHelper.new.update_companies_batch(@api_controller, @debug, company_profiles)
    end

    def start_with_json(body)
      body.start_with?("{") || body.start_with?("[")
    end

    def decompress_body(body)
      Zlib::GzipReader.new(StringIO.new(body)).read
    end

    def base64_encode_body(data)
      return Base64.encode64(data), "base64"
    end

    def is_base64_str(body)
      if not body.instance_of?(String)
        return false
      end
      if body.length % 4 != 0
        return false
      end

      b64_regex = /^[A-Za-z0-9+\/]+={0,2}$/

      if not body.match?(b64_regex)
        return false
      end

      begin
        _ = Base64.decode64(body)
        return true
      rescue
        return false
      end

    end

    def @moesif_helpers.log_debug(message)
      if @debug
        puts("#{Time.now.to_s} [Moesif Middleware] PID #{Process.pid} TID #{Thread.current.object_id} #{message}")
      end
    end

    def process_body(body_wrapper, headers)
      # the `event` object can either be a Hash or a String
      if body_wrapper.instance_of?(Hash) and body_wrapper.key?("body")
        body = body_wrapper.fetch("body")
        begin
          if body_wrapper.fetch("isBase64Encoded", false) and is_base64_str(body)
            return body, "base64"
          else
            return safe_json_parse(body, headers)
          end
          rescue
            return base64_encode_body(body)
        end
      elsif body_wrapper.instance_of?(String)
        return base64_encode_body(body_wrapper)
      else
        return nil, nil
      end
    end

    def safe_json_parse(body, headers)
      begin
        if (body.instance_of?(Hash) || body.instance_of?(Array))
          parsed_body = body
          transfer_encoding = "json"
        elsif start_with_json(body)
          parsed_body = JSON.parse(body)
          transfer_encoding = "json"
        elsif headers.key?("content-encoding") && ((headers["content-encoding"].downcase).include? "gzip")
          uncompressed_string = decompress_body(body)
          parsed_body, transfer_encoding = base64_encode_body(uncompressed_string)
        else
          parsed_body, transfer_encoding = base64_encode_body(body)
        end
      rescue
        parsed_body, transfer_encoding = base64_encode_body(body)
      end
      return parsed_body, transfer_encoding
    end

    def start_worker(event_model)
      thr = Thread::new do
        @moesif_helpers.log_debug("start worker")

        begin
            batch_events = [ event_model ]
            @moesif_helpers.log_debug("Sending #{batch_events.size.to_s} events to Moesif")
            event_api_response = @api_controller.create_events_batch(batch_events)
            @event_response_config_etag = event_api_response[:x_moesif_config_etag]
            @moesif_helpers.log_debug(event_api_response.to_s)
            @moesif_helpers.log_debug("Events successfully sent to Moesif")
        rescue MoesifApi::APIException => e
          if e.response_code.between?(401, 403)
            puts "Unathorized accesss sending event to Moesif. Please verify your Application Id."
            @moesif_helpers.log_debug(e.to_s)
          end
          @moesif_helpers.log_debug("Error sending event to Moesif, with status code #{e.response_code.to_s} #{e.to_s}")
        end

      end

      thr.join
    end

    def handle(event:, context:)
      payload_format_version_1_0 = event["version"] == "1.0"

      # Request Time
      if payload_format_version_1_0
        epoch = event.dig("requestContext", "requestTimeEpoch")
      else
        epoch = event.dig("requestContext", "timeEpoch")
      end
      if epoch.nil?
        start_time = Time.now.utc.iso8601(3)
      else
        # divide by 1000 to preserve the milliseconds
        start_time = Time.at(epoch / 1000.0).utc.iso8601(3)
      end
      # preserve request headers here in case it is changed down stream.
      req_headers = get_request_headers(event, context, payload_format_version_1_0)

      @moesif_helpers.log_debug("Calling Moesif middleware")

      begin
        lambda_result = @handler.call(event: event, context: context)
      rescue Exception => customer_exception
        execution_error = customer_exception
      end

      end_time = Time.now.utc.iso8601(3)

      process_send = lambda do
        # REQUEST
        event_req = MoesifApi::EventRequestModel.new()

        event_req.time = start_time
        event_req.uri = build_uri(event, context, payload_format_version_1_0)
        event_req.verb = get_request_verb(event, context, payload_format_version_1_0)

        # extract below from lambda_result
        if execution_error
          # so we can still continue
          @moesif_helpers.log_debug("an exception occured with original execution, so capture that.")
          status = 500
          rsp_body = { "message" => "Internal Server Error" }
          rsp_headers = {}
          rsp_body_transfer_encoding = nil
        else
          status, rsp_headers, rsp_body, rsp_body_transfer_encoding = get_response_info_from_lambda_result(lambda_result)
        end

        if @api_version
          event_req.api_version = @api_version
        end

        # Add Transaction Id to the Request Header
        if !@disable_transaction_id
          req_trans_id = req_headers["X-MOESIF_TRANSACTION_ID"]
          if !req_trans_id.nil?
            transaction_id = req_trans_id
            if transaction_id.strip.empty?
              transaction_id = SecureRandom.uuid
            end
          else
            transaction_id = SecureRandom.uuid
          end
          # Add Transaction Id to Request Header
          req_headers["X-Moesif-Transaction-Id"] = transaction_id
          # Filter out the old key as HTTP Headers case are not preserved
          if req_headers.key?("X-MOESIF_TRANSACTION_ID")
            req_headers = req_headers.except("X-MOESIF_TRANSACTION_ID")
          end
        end

        event_req.ip_address = get_ip_address(event, context, payload_format_version_1_0)
        event_req.headers = req_headers

        if @log_body
          if event.key?("body") and event.fetch("isBase64Encoded") and is_base64_str(event.fetch("body"))
            event_req.body= event.fetch("body") 
            event_req.transfer_encoding = "base64"
          else
            event_req.body, event_req.transfer_encoding = process_body(event, req_headers)
          end
        end

        # RESPONSEE
        event_rsp = MoesifApi::EventResponseModel.new()
        event_rsp.time = end_time

        # Add Transaction Id to the Response Header
        if !transaction_id.nil?
          rsp_headers["X-Moesif-Transaction-Id"] = transaction_id
        end

        event_rsp.status = status
        event_rsp.headers = rsp_headers

        if @log_body
          event_rsp.body = rsp_body
          event_rsp.transfer_encoding = rsp_body_transfer_encoding
        end

        event_model = MoesifApi::EventModel.new()
        event_model.request = event_req
        event_model.response = event_rsp
        event_model.direction = "Incoming"

        if @identify_user
          @moesif_helpers.log_debug "calling identify user proc"
          event_model.user_id = @identify_user.call(event, context, lambda_result)
        end

        if @identify_company
          @moesif_helpers.log_debug "calling identify company proc"
          event_model.company_id = @identify_company.call(event, context, lambda_result)
        end

        if @get_metadata
          @moesif_helpers.log_debug "calling get_metadata proc"
          event_model.metadata = @get_metadata.call(event, context, lambda_result)
        else
          @moesif_helpers.log_debug "create default metadata"
          ## get default metadata from context object?
          contextHash = {}
          context.instance_variables.each {|var| contextHash[var.to_s.delete("@")] = context.instance_variable_get(var) }
          event_model.metadata = {
            "trace_id" => context.aws_request_id.to_s,
            "function_name" => context.function_name,
            "request_context" => event["requestContext"],
            "context" => contextHash
          }
          @moesif_helpers.log_debug JSON.generate(event_model.metadata)
        end

        if @identify_session
          @moesif_helpers.log_debug "calling identify session proc"
          event_model.session_token = @identify_session.call(event, context, lambda_result)
        end
        if @mask_data
          @moesif_helpers.log_debug "calling mask_data proc"
          event_model = @mask_data.call(event_model)
        end

        @moesif_helpers.log_debug "sending data to moesif"
        @moesif_helpers.log_debug event_model.to_json

        # send event directly
        start_worker(event_model)
      end # end process_send

      should_skip = false

      if @skip
        if @skip.call(event, context, lambda_result)
          should_skip = true
        end
      end

      if !should_skip
        begin
          process_send.call
        rescue => exception
          @moesif_helpers.log_debug "Error while logging event - "
          @moesif_helpers.log_debug exception.to_s
          @moesif_helpers.log_debug exception.backtrace
        end
      else
        @moesif_helpers.log_debug "Skipped Event using should_skip configuration option."
      end

      # return original result
      # or raise original exception
      if execution_error
        @moesif_helpers.log_debug "raise original exception that happened."
        raise execution_error
      else
        @moesif_helpers.log_debug "return original lambda result."
        lambda_result
      end
    end
  end
end
