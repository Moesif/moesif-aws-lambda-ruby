require 'json'

def my_handler(event:,context:)
  { event: JSON.generate(event), context: JSON.generate(context.inspect), my_test: 12342 }
end

puts "here"

def middleware_new(hand, options)
  puts hand
  Proc.new { |event:, context:|
    puts "inside wrapped middleware proc"
    result = hand.call(event: event, context: context);
    puts "finished calling wrapped handler"
    result
  }
end

puts 'helloword'

my_var = 5

test_scope = Proc.new {
  puts 'in test scope'
  puts my_var
}

test_scope.call()

def final_handler(event:, context:)
  puts 'final handler called'
  new_proc = middleware_new(method(:my_handler), { appplication_id: 1234234 })
  puts 'here triggering new_proc'
  new_proc.call(event: event, context: context)
end


puts final_handler(event: { nihao: 1234 }, context: { foo: 123412 });
