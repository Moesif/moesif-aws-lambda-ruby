require 'rspec'
require 'json'
require_relative '../lib/moesif_aws_lambda'

class AwsContext
  attr_accessor :aws_request_id, :function_name

  def initialize
    @function_name = 'test function'
    @function_version = '123421'
    @aws_request_id = Time.now.to_i
  end
end

fake_event_str = {
  'rawPath' => '/test/route',
  'headers' => {
    'foo' => 'bar'
  },
  'requestContext' => {
    'http' => {
      'method' => 'post'
    }
  },
  'isBase64Encoded' => true,
  'body' => 'hello world'
}
fake_event_hash = {
  'rawPath' => '/test/route',
  'headers' => {
    'foo' => 'bar'
  },
  'requestContext' => {
    'http' => {
      'method' => 'post'
    }
  },
  'isBase64Encoded' => true,
  'body' => {
    'msg' => 'Hello world!',
    'city' => 'New York',
    'year' => 2024
  }
}
fake_event_json = {
  'rawPath' => '/test/route',
  'headers' => {
    'foo' => 'bar'
  },
  'requestContext' => {
    'http' => {
      'method' => 'post'
    }
  },
  'isBase64Encoded' => true,
  'body' => '{
    "foo": "bar",
    "year": 2024
  }'
}
fake_event_b64 = {
  'rawPath' => '/test/route',
  'headers' => {
    'foo' => 'bar'
  },
  'requestContext' => {
    'http' => {
      'method' => 'post'
    }
  },
  'isBase64Encoded' => true,
  'body' => 'eyJmb28iOiJiYXIifQ=='
}

describe Moesif::MoesifAwsMiddleware do
  handler = Proc.new{ |event:, context:|
    { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12_342 }
  }
  options = {
    'application_id' => '',
    'debug' => true
  }

  let(:moesif) { Moesif::MoesifAwsMiddleware.new(handler, options) }

  describe '#process_body' do
    it 'parses a string body correctly' do
      body, transfer_encoding = moesif.process_body(fake_event_str, fake_event_str.fetch('headers'))
      expect(transfer_encoding).to eq('base64')
      expect(body == 'aGVsbG8gd29ybGQ=')
    end
    it 'parses a hash body correctly' do
      body, transfer_encoding = moesif.process_body(fake_event_hash, fake_event_hash.fetch('headers'))
      expect(transfer_encoding).to eq('json')
      expect(body.instance_of?(Hash)).to be true
    end
    it 'parses a JSON body correctly' do
      body, transfer_encoding = moesif.process_body(fake_event_json, fake_event_json.fetch('headers'))
      expect(transfer_encoding).to eq('json')
      expect(body.instance_of?(Hash)).to be true
    end
    it 'parses a valid base64-encoded body correctly' do
      body, transfer_encoding = moesif.process_body(fake_event_b64, fake_event_b64.fetch('headers'))
      expect(transfer_encoding).to eq('base64')
      expect(body).to eq('eyJmb28iOiJiYXIifQ==')
    end
  end

  describe '#is_base64_str' do
    it 'returns true for a valid base64-encoded string' do
      valid_base64 = 'eyJmb28iOiJiYXIifQ=='
      expect(moesif.is_base64_str(valid_base64)).to be true
    end
    it 'returns false for an invalid base64-encoded string' do
      invalid_base64 = {
        'name' => 'Alex',
        'age' => 27
      }
      expect(moesif.is_base64_str(invalid_base64)).to be false
    end
  end

  describe '.handle' do
    it 'returns a Lambda result as a Hash object' do
      result = moesif.handle(event: fake_event_str, context: AwsContext.new)
      puts result
      expect(result.instance_of?(Hash)).to be true
    end
  end
end
