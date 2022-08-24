

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


def get_request_verb(event, context)


end

def get_request_headers(event, context)

  req_headers = {}
  try:
      if 'headers' in event:
          req_headers = APIHelper.json_deserialize(event['headers'])
  except Exception as e:
      if self.DEBUG:
          print('MOESIF Error while fetching request headers')
          print(e)

  req_headers
end

def get_ip_address(event, context):

def process_body(body_wrapper):
  """Function to process body"""
  if not (self.LOG_BODY and body_wrapper.get('body')):
      return None, 'json'

  body = None
  transfer_encoding = None
  try:
      if body_wrapper.get('isBase64Encoded', False):
          body = body_wrapper.get('body')
          transfer_encoding = 'base64'
      else:
          if isinstance(body_wrapper['body'], str):
              body = json.loads(body_wrapper.get('body'))
          else:
              body = body_wrapper.get('body')
          transfer_encoding = 'json'
  except Exception as e:
      body = base64.b64encode(str(body_wrapper['body']).encode("utf-8"))
      if isinstance(body, str):
          return str(body).encode("utf-8"), 'base64'
      elif isinstance(body, (bytes, bytearray)):
          return str(body, "utf-8"), 'base64'
      else:
          return str(body), 'base64'
  body, transfer_encoding
end

def get_ip_address(event, context):



def get_response(labmda_result)

end
