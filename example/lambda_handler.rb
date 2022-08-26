require "json"
require_relative "../lib/moesif_aws_middleware";

def my_handler(event:, context:)
  { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
end

puts "here"

$moesif_middleware = Moesif::MoesifAwsMiddleware.new(method(:my_handler), {
  "application_id" => '12341241241242'
})

def wrapped_handler(event:, context:)
  $moesif_middleware.echo_me()
  $moesif_middleware.handle(event: event, context: context);
end

result = wrapped_handler(event: { "test": "1234" }, context: { inspect: "foobar"})

puts "final results is"
puts JSON.generate(result);

def middleware_new(hand, options)
  puts hand
  Proc.new { |event:, context:|
    puts "inside wrapped middleware proc"
    result = hand.call(event: event, context: context)
    puts "finished calling wrapped handler"
    result
  }
end
