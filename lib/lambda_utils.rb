
def build_uri(event, context, payload_format_version_1_0)
  protocol = (event["headers"] || {}).fetch("X-Forwarded-Proto", event["headers"].fetch("x-forwarded-proto", "http")) + "://"
  host = (event["headers"] || {}).fetch("Host", event["headers"].get("host", "localhost"))

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
    verb = event.fetch("httpMethod", "GET");
  verb
end

def get_request_headers(event, context, payload_format_version_1_0)
  req_headers = event.headers
  if payload_format_version_1_0
    if event.include? "multiValueHeaders"
      req_headers = (event['multiValueHeaders'] || {}).transform_values do |value|
        value.join("\n")
      end
    end
  req_headers
end

def get_ip_address(event, context, payload_format_version_1_0):
  ip_address = event.dig('requestContext', 'http', 'sourceIp')
  if payload_format_version_1_0
    ip_address = event.dig('requestContext', 'identity', 'sourceIp')
  end
  ip_address
end
