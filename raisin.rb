class AssertionError < StandardError
end

class NothingRaised < StandardError
end

def test_failure(&block)
  raised = false
  begin
    yield
  rescue AssertionError
    raised = true
  end
  raise NothingRaised unless raised
end

def assert(condition, failure_reason = nil)
  unless condition
    raise AssertionError, failure_reason
  end
end

assert(true)

test_failure do
  assert(false)
end


def assert_equal(expected, actual)
  message = "Expected #{expected.inspect}, got #{actual.inspect}"
  assert(expected == actual, message)
end

assert_equal(true, true)

test_failure do
  assert_equal("foo", "bar")
end


puts "Success!"
