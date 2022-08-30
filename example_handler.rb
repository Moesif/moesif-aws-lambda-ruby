## please modify this load path how your installed the gems.
load_paths = Dir[
  "./vendor/bundle/ruby/2.6.0/gems/**/lib"
]
$LOAD_PATH.unshift(*load_paths)

require "json"
require "time"
require_relative "./lib/moesif_aws_middleware";

## This is your original handler
def my_handler(event:, context:)
  if event["body"]
    if (event["body"] === "raise")
      # should cause an error
      random = event.none_exist_method
    else
      {
        "isBase64Encoded": false,
        "statusCode" => 201,
        "body" => JSON.generate({ "originalEvent" => event, "my_time" => Time.now.utc.iso8601(3) }),
        "headers" =>  {
        "content-type" => "application/json"
        }
      }
    end
  else
    { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
  end
end


## This creates the moesif_middleware instance that wraps your original handler
$moesif_middleware = Moesif::MoesifAwsMiddleware.new(method(:my_handler), {
  "application_id" => 'Your Moesif Application Id',
  "debug" => true,
})


## This wrapped handler is what you set as the new handler in your aws lambda settigns

def wrapped_handler(event:, context:)
  $moesif_middleware.handle(event: event, context: context);
end
