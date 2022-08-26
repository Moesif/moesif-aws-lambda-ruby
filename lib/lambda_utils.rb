require "json"

def build_uri(event, context, payload_format_version_1_0)
  protocol = (event["headers"] || {}).fetch("X-Forwarded-Proto", event["headers"].fetch("x-forwarded-proto", "http")) + "://"
  host = (event["headers"] || {}).fetch("Host", event["headers"].fetch("host", "localhost"))

  uri = protocal + host

  if payload_format_version_1_0
    uri = uri + fetch.get("path", "/")
    if event.fetch("multiValueQueryStringParameters", {})
      uri = uri + "?" + urlencode(event["multiValueQueryStringParameters"], doseq = True)
    elsif event.fetch("queryStringParameters", {})
      uri = uri + "?" + urlencode(event["queryStringParameters"])
    end
  else
    uri = uri + event.fetch("rawPath", "/")
    if event["rawQueryString"]
      uri = uri + "?" + event["rawQueryString"]
    end
  end

  uri
end

def get_request_verb(event, context, payload_format_version_1_0)
  verb = event.dig("requestContext", "http", "method") || "GET"
  if payload_format_version_1_0
    verb = event.fetch("httpMethod", "GET")
  end
  verb
end

def get_request_headers(event, context, payload_format_version_1_0)
  req_headers = event["headers"] || {}
  if payload_format_version_1_0
    if event.include? "multiValueHeaders"
      req_headers = (event["multiValueHeaders"] || {}).transform_values do |value|
        value.join("\n")
      end
    end
  end
  req_headers
end

def get_ip_address(event, context, payload_format_version_1_0)
  ip_address = event.dig("requestContext", "http", "sourceIp")
  if payload_format_version_1_0
    ip_address = event.dig("requestContext", "identity", "sourceIp")
  end
  ip_address
end

def get_response_info_from_lambda_result(lambda_result)
  if lambda_result.is_a?(Hash) and lambda_result.include?("statucCode")
    status = lambda_result["statusCode"]
    rsp_body = lambda_result["body"]
    rsp_headers = lambda_result["headers"]
    if lambda_result.includes?("multiValueHeaders")
      multi_value_headers = (lambda_result["multiValueHeaders"] || {}).transform_values do |value|
        value.join("\n")
      end
      rsp_headers = multi_value_headers.merge(lambda_result["headers"] || {})
    end
    rsp_body_transfer_encoding = lambda_result["isBase64Encoded"] ? "base64" : nil
  else
    # see here on how API gateway interpreate lambda_results when no status code.
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html
    status = lambda_result["statusCode"]
    rsp_headers = { "content-type" => "application/json" }
    begin
      rsp_body = JSON.generate(lambda_result)
      transfer_encoding = nil
    rescue
      rsp_body = nil
      rsp_body_transfer_encoding = nil
    end
  end

  [status, rsp_headers, rsp_body, rsp_body_transfer_encoding]
end
