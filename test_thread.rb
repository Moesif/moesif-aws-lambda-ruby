

def start_thread
  puts "start thread"
  t1 = Thread.new {
    sleep 3
    puts 'inside sthread'
  }
  puts "end of thread"
  "this is return value of function"
end

result = start_thread()
puts "got output back #{result}"
sleep 6
puts "finished sleeping for 6 seconds"
