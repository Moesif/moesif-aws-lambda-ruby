require "moesif_aws_lambda";

puts "hello world"

$moesif_middleware = Moesif::MoesifAwsMiddleware.new("abc", {
  "application_id" => 'Your Moesif Application Id',
  "debug" => true,
})

puts $moesif_middleware.inspect