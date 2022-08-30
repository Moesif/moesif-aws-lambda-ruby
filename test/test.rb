require "moesif_aws_lambda";
require "time";

puts "hello world"

handler = Proc.new { |event:, context:|
  { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
}

$moesif_middleware = Moesif::MoesifAwsMiddleware.new(handler, {
  "application_id" => 'Your Applicatoin Id',
  "debug" => true,
})

puts $moesif_middleware.inspect

class AwsContext
  attr_accessor :aws_request_id, :function_name

  def initialize
    @function_name = "test function"
    @function_version = "123421"
    @aws_request_id = Time.now.to_i
  end
end

fake_context = AwsContext.new

fake_event = {
  "rawPath" => "/test/route",
  "headers" => {
    "foo" => "bar"
  },
  "requestContext" => {
    "http" => {
      "method" => "post"
    }
  },
  "body" => "hello world"
}

$moesif_middleware.handle(event: fake_event, context: fake_context)
