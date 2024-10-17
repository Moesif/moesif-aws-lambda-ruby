# Moesif AWS Lambda Middleware for Ruby
by [Moesif](https://moesif.com), the [API analytics](https://www.moesif.com/features/api-analytics) and [API monetization](https://www.moesif.com/solutions/metered-api-billing) platform.

[![Built For][ico-built-for]][link-built-for]
[![Software License][ico-license]][link-license]
[![Source Code][ico-source]][link-source]

With Moesif Ruby middleware for AWS Lambda, you can automatically log API calls 
and send them to [Moesif](https://www.moesif.com) for API analytics and monitoring.
This middleware allows you to integrate Moesif's API analytics and 
API monetization features into your Ruby applications with minimal configuration.

> If you're new to Moesif, see [our Getting Started](https://www.moesif.com/docs/) resources to quickly get up and running.

This middleware expects the
[Lambda proxy integration type.](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-set-up-simple-proxy.html#api-gateway-set-up-lambda-proxy-integration-on-proxy-resource)
If you're using AWS Lambda with API Gateway, you are most likely using the proxy integration type.

## Prerequisites
Before using this middleware, make sure you have the following:

- [An active Moesif account](https://moesif.com/wrap)
- [A Moesif Application ID](#get-your-moesif-application-id)

### Get Your Moesif Application ID
After you log into [Moesif Portal](https://www.moesif.com/wrap), you can get your Moesif Application ID during the onboarding steps. You can always access the Application ID any time by following these steps from Moesif Portal after logging in:

1. Select the account icon to bring up the settings menu.
2. Select **Installation** or **API Keys**.
3. Copy your Moesif Application ID from the **Collector Application ID** field.

<img class="lazyload blur-up" src="images/app_id.png" width="700" alt="Accessing the settings menu in Moesif Portal">

## Install the Middleware

Install with [Bundler](https://bundler.io/):

```shell
bundle install moesif_aws_lambda
```

## Configure the Middleware
See the available [configuration options](#configuration-options) to learn how to configure the middleware for your use case. 

## How to use

### 1. Wrap your Original Lambda handler with Moesif Middleware


```ruby

def your_original_handler(event:, context:)
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


### 2. Create a Wrapped Handler and Set it to the Function Handler Name


```ruby
def wrapped_handler(event:, context:)
  $moesif_middleware.handle(event: event, context: context);
end
```

Then set the AWS Lambda handler name to `wrapped_handler` instead. For more information, see [Define Lambda function handler in Ruby](https://docs.aws.amazon.com/lambda/latest/dg/ruby-handler.html?icmpid=docs_lambda_help).

## Troubleshoot
For a general troubleshooting guide that can help you solve common problems, see [Server Troubleshooting Guide](https://www.moesif.com/docs/troubleshooting/server-troubleshooting-guide/).

Other troubleshooting supports:

- [FAQ](https://www.moesif.com/docs/faq/)
- [Moesif support email](mailto:support@moesif.com)

## Configuration Options
The following sections describe the available configuration options for this middleware. You must set these options in a Ruby `Hash` object when you create the middleware instance. See the sample Lambda handler function code in `example_handler.rb` for better understanding.

### __`application_id`__ (Required)
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
  </tr>
  <tr>
   <td>
    String
   </td>
  </tr>
</table>

A string that [identifies your application in Moesif](#get-your-moesif-application-id).

### __`api_version`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
  </tr>
  <tr>
   <td>
    String
   </td>
  </tr>
</table>

Optional.

Use it to tag requests with the version of your API.


#### __`identify_user`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    String
   </td>
  </tr>
</table>

Optional, but highly recommended.

A `Proc` that takes the event, context, and Lambda result as arguments.

Returns a string that represents the user ID used by your system. 

Moesif identifies users automatically. However, due to the differences arising from different frameworks and implementations, set this option to ensure user identification properly.

In the following code snippet, `event` and `context` are original Lambda handler's input parameters. `result` is the return result from your own original Lambda handler.

```ruby
moesif_options['identify_user'] = Proc.new { |event, context, result|

  # Add your custom code that returns a string for user id
  '12345'
}

```

#### __`identify_company`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    String
   </td>
  </tr>
</table>

Optional.

A `Proc` that takes the event, context, and Lambda result as arguments.


Returns a string that represents the company ID for this event. This helps Moesif attribute requests to unique company.

```ruby
moesif_options['identify_company'] = Proc.new { |event, context, result|

  # Add your custom code that returns a string for company id
  '67890'
}

```

#### __`identify_session`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    String
   </td>
  </tr>
</table>

A `Proc` that takes `env`, `headers`, and `body` as arguments.

Returns a string that represents the session token for this event. 

Similar to users and companies, Moesif tries to retrieve session tokens automatically. But if it doesn't work for your service, use this option to help identify sessions.

```ruby

moesif_options['identify_session'] = Proc.new { |event, context, result|
    # Add your custom code that returns a string for session/API token
    'XXXXXXXXX'
}
```

#### __`get_metadata`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    <code>Hash</code>
   </td>
  </tr>
</table>

Optional.

A `Proc` that takes `env`, `headers`, and `body` as arguments.

Returns a `Hash` that represents a JSON object. This allows you to attach any
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
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    <code>EventModel</code>
   </td>
  </tr>
</table>

Optional. 

A Proc that takes an `EventModel` as an argument and returns an `EventModel`.

This option allows you to modify headers or body of an event before sending the event to Moesif.

```ruby

moesif_options['mask_data'] = Proc.new { |event_model|
  # Add your custom code that returns a event_model after modifying any fields
  event_model.response.body.password = nil
  event_model
}

```

For more information and the spec of Moesif's event model, see the source code of [Moesif API library for Ruby](https://github.com/Moesif/moesifapi-ruby) or [Moesif Ruby API documentation](https://www.moesif.com/docs/api?ruby)


#### __`skip`__

<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Return type
   </th>
  </tr>
  <tr>
   <td>
    <code>Proc</code>
   </td>
   <td>
    Boolean
   </td>
  </tr>
</table>

Optional.

A `Proc` that takes `env`, `headers`, and `body` as arguments.

Returns a boolean. Return `true` if you want to skip a particular event.


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



#### __`debug`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Default
   </th>
  </tr>
  <tr>
   <td>
    Boolean
   </td>
   <td>
    <code>false</code>
   </td>
  </tr>
</table>

Optional.

If `true`, the middleware prints out debug messages. In debug mode, the processing is not done in backend thread.

#### __`log_body`__
<table>
  <tr>
   <th scope="col">
    Data type
   </th>
   <th scope="col">
    Default
   </th>
  </tr>
  <tr>
   <td>
    Boolean
   </td>
   <td>
    <code>true</code>
   </td>
  </tr>
</table>

Optional.

If `false`, doesn't log request and response body to Moesif.

## Additional Methods for Updating User and Company Profiles

If you want to update [User](https://www.moesif.com/docs/getting-started/users/) or [Company](https://www.moesif.com/docs/getting-started/companies/) profile using this SDK, use the following methods:

``` ruby
$moesif_middleware.update_user(user_profile)
$moesif_middleware.update_user_batch(user_profiles)
$moesif_middleware.update_company(company_profile)
$moesif_middleware.update_company_batch(company_profiles)
```

For information about the structure of profiles, see [Moesif Ruby API documentation](https://www.moesif.com/docs/api?ruby)

## Examples

See `example_handler.rb` that contains an example Lambda handler using this middleware.


## Bundling Your Gem Files

For AWS Lambda with Ruby, you have to bundle the gem dependencies into a ZIP file archive. For instructions, see [Deploy Ruby Lambda functions with .zip file archives](https://docs.aws.amazon.com/lambda/latest/dg/ruby-package.html).

In the file where you define your Lambda handler, you may have to specify the location of the dependencies:

```ruby
load_paths = Dir[
  "./vendor/bundle/ruby/2.7.0/gems/**/lib"
]
$LOAD_PATH.unshift(*load_paths)
```

## How to Get Help
If you face any issues using this middleware, try the [troubheshooting guidelines](#troubleshoot). For further assistance, reach out to our [support team](mailto:support@moesif.com).

## Explore Other Integrations

Explore other integration options from Moesif:

- [Server integration options documentation](https://www.moesif.com/docs/server-integration//)
- [Client integration options documentation](https://www.moesif.com/docs/client-integration/)

[ico-built-for]: https://img.shields.io/badge/built%20for-aws%20lambda-blue.svg
[ico-license]: https://img.shields.io/badge/License-Apache%202.0-green.svg
[ico-source]: https://img.shields.io/github/last-commit/moesif/moesif-aws-lambda-ruby.svg?style=social

[link-built-for]: https://aws.amazon.com/lambda/
[link-license]: https://raw.githubusercontent.com/Moesif/moesif-aws-lambda-ruby/master/LICENSE
[link-source]: https://github.com/moesif/moesif-aws-lambda-ruby