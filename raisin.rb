class AssertionError < StandardError
end

class NothingRaised < StandardError
end

def assert(condition)
  raise AssertionError unless condition
end

assert(true)

raised = false
begin
  assert(false)
rescue AssertionError
  raised = true
end
raise NothingRaised unless raised

puts "Success!"
