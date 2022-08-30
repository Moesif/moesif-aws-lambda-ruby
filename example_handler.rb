## modify the load path to reflect how your installed the gems before zip and upload to aws lambda
load_paths = Dir[
  "./vendor/bundle/ruby/2.6.0/gems/**/lib"
]
$LOAD_PATH.unshift(*load_paths)

require "json"
require "time"
require "moesif_aws_lambda"

## This is your original handler
def my_handler(event:, context:)
  if event["body"]
    if (event["body"] === "raise")
      # an example where original handler have an error.
      # moesif middleware will still capture the call
      # and propogate the exception.
      random = event.none_exist_method
    else
      # an example where original handler uses the standard format for lambda result
      {
        "isBase64Encoded": false,
        "statusCode" => 201,
        "body" => JSON.generate({ "originalEvent" => event, "my_time" => Time.now.utc.iso8601(3), "message": "hello" }),
        "headers" =>  {
          "content-type" => "application/json"
        }
      }
    end
  else
    # an example where orginal handler do not return statusCode
    # API gateway will have interpret as 200 and entire json as body
    { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
  end
end

## This creates the moesif_middleware instance that wraps your original handler
$moesif_middleware = Moesif::MoesifAwsMiddleware.new(method(:my_handler), {
  "application_id" => 'Your Application Id',
  "debug" => true,
  "identify_user" => Proc.new { |event, context, result|
    # Add your custom code that returns a string for user id
    puts "identify user is called"
    'user_id_12345'
  }
})

## This wrapped handler is what you set as the new handler in your aws lambda settings
def wrapped_handler(event:, context:)
  $moesif_middleware.handle(event: event, context: context);
end
