require "json"

def my_handler(event:, context:)
  { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
end

puts "here"

def middleware_new(hand, options)
  puts hand
  Proc.new { |event:, context:|
    puts "inside wrapped middleware proc"
    result = hand.call(event: event, context: context)
    puts "finished calling wrapped handler"
    result
  }
end

puts "helloword"

my_var = 5

test_scope = Proc.new {
  puts "in test scope"
  puts my_var
}

test_scope.call()

def final_handler(event:, context:)
  puts "final handler called"
  new_proc = middleware_new(method(:my_handler), { appplication_id: 1234234 })
  puts "here triggering new_proc"
  new_proc.call(event: event, context: context)
end

puts final_handler(event: { nihao: 1234 }, context: { foo: 123412 })

my_hash = { abc: { bar: 2342 } }

my_hash_with_strings = { "abc" => { "bar" => 1111 } }

puts "use string [] #{my_hash_with_strings["abc"]}"
puts "use string #{my_hash_with_strings.dig("abc", "bar")}"
puts "dig abc bar #{my_hash.dig(:abc, :bar)}"
puts "dig abc #{my_hash.dig(:abc)}"
puts "dig abc foo #{my_hash.dig(:abc, :foo)}"
puts "dig foo bar #{my_hash.dig(:foo, :bar).nil?}"

puts "fetch abc #{my_hash_with_strings.fetch("abc", "default value")}"
puts "fetch foo #{my_hash_with_strings.fetch("foo", "default value")}"
