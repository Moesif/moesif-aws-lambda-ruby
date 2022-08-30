# Moesif AWS Lambda Middleware Ruby

[![Built For][ico-built-for]][link-built-for]
[![Software License][ico-license]][link-license]
[![Source Code][ico-source]][link-source]

Middleware (Ruby) to automatically log API calls from AWS Lambda functions and sends
and sends to [Moesif](https://www.moesif.com) for API analytics.

This middleware expects the
[Lambda proxy integration type.](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-set-up-simple-proxy.html#api-gateway-set-up-lambda-proxy-integration-on-proxy-resource)
If you're using AWS Lambda with API Gateway, you are most likely using the proxy integration type.


## How to install

```shell
bundle install moesif_aws_lambda
```

## How to use

### 1. Wrap your original lambda handler with Moesif Middleware


```ruby

def your_original_handler(event: context)
   # your code
end

moesif_options = {
  # application_id is required
  "application_id" => 'Your Moesif Application Id',
  "debug" => true,
  # see list of other options below.
}

# create moesif_middleware object.
$moesif_middleware = Moesif::MoesifAwsMiddleware.new(method(:your_original_handler), moesif_options)
```


### 2. create a wrapped handler and set AWS lambda to use this.

```Ruby
def wrapped_handler(event:, context:)
  $moesif_middleware.handle(event: event, context: context);
end
```

configure AWS Lambda handler to `wrapped_handler` instead.


## Configuration Options

#### __`application_id`__

Required. String. This is the Moesif application_id under settings
from your [Moesif account.](https://www.moesif.com)


#### __`api_version`__

Optional. String. Tag requests with the version of your API.


#### __`identify_user`__

Optional.
identify_user is a Proc that takes event, context, and lambda result as arguments and returns a user_id string. This helps us attribute requests to unique users. Even though Moesif can automatically retrieve the user_id without this, this is highly recommended to ensure accurate attribution.

`event` and `context` are original lambda input params, and `result` is the return result from your own original lambda handler.

```ruby
moesif_options['identify_user'] = Proc.new { |event, context, result|

  # Add your custom code that returns a string for user id
  '12345'
}

```

#### __`identify_company`__

Optional.
identify_company returns a company_id string. This helps us attribute requests to unique company.

```ruby
moesif_options['identify_company'] = Proc.new { |event, context, result|

  # Add your custom code that returns a string for company id
  '67890'
}

```

#### __`identify_session`__

Optional. A Proc that takes env, headers, body and returns a string.

```ruby

moesif_options['identify_session'] = Proc.new { |event, context, result|
    # Add your custom code that returns a string for session/API token
    'XXXXXXXXX'
}
```

#### __`get_metadata`__

Optional.
get_metadata is a Proc that takes env, headers, and body as arguments and returns a Hash that is
representation of a JSON object. This allows you to attach any
metadata to this event.

```ruby

moesif_options['get_metadata'] = Proc.new { |event, context, result|
  # Add your custom code that returns a dictionary
  value = {
      'datacenter'  => 'westus',
      'deployment_version'  => 'v1.2.3'
  }
  value
}
```


#### __`mask_data`__

Optional. A Proc that takes event_model as an argument and returns event_model.

With mask_data, you can make modifications to headers or body of the event before it is sent to Moesif.

```ruby

moesif_options['mask_data'] = Proc.new { |event_model|
  # Add your custom code that returns a event_model after modifying any fields
  event_model.response.body.password = nil
  event_model
}

```

For details for the spec of moesif event model, please see the [moesifapi-ruby](https://github.com/Moesif/moesifapi-ruby)

#### __`skip`__

Optional. A Proc that takes env, headers, body and returns a boolean.

```ruby

moesif_options['skip'] = Proc.new { |event, context, result|
  # Add your custom code that returns true to skip logging the API call
  if event.key?("rawPath")
      # Skip probes to health page
    event["rawPath"].include? "/health"
  else
      false
  end
}

```

For details for the spec of event model, please see the [Moesif Ruby API Documentation](https://www.moesif.com/docs/api?ruby)


#### __`debug`__

Optional. Boolean. Default false. If true, it will print out debug messages. In debug mode, the processing is not done in backend thread.

#### __`log_body`__

Optional. Boolean. Default true. If false, will not log request and response body to Moesif.


## Additional Methods for Updating User and Company Profile

If you wish to update User or Company profile when needed using this SDK, you can also use below methods:

``` ruby
$moesif_middleware.update_user(user_profile)
$moesif_middleware.update_user_batch(user_profiles)
$moesif_middleware.update_company(company_profile)
$moesif_middleware.update_company(company_profiles)
```

For details regarding shape of the profiles, please see the [Moesif Ruby API Documentation](https://www.moesif.com/docs/api?ruby)


## Notes Regarding Bundling Your Gem Files

For AWS lambda with ruby, you have to bundle the gem dependencies into the zip file.
https://docs.aws.amazon.com/lambda/latest/dg/ruby-package.html

In your ruby main file, you may have to specify where the dependencies are installed:

```ruby
load_paths = Dir[
  "./vendor/bundle/ruby/2.7.0/gems/**/lib"
]
$LOAD_PATH.unshift(*load_paths)
```

## Example

`example_handler.rb` is an example file that implement this.


[ico-built-for]: https://img.shields.io/badge/built%20for-aws%20lambda-blue.svg
[ico-license]: https://img.shields.io/badge/License-Apache%202.0-green.svg
[ico-source]: https://img.shields.io/github/last-commit/moesif/moesif-aws-lambda-ruby.svg?style=social

[link-built-for]: https://aws.amazon.com/lambda/
[link-license]: https://raw.githubusercontent.com/Moesif/moesif-aws-lambda-ruby/master/LICENSE
[link-source]: https://github.com/moesif/moesif-aws-lambda-python