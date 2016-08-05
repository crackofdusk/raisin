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

def assert(condition)
  raise AssertionError unless condition
end

assert(true)

test_failure do
  assert(false)
end


def assert_equal(expected, actual)
  assert(expected == actual)
end

assert_equal(true, true)

test_failure do
  assert_equal("foo", "bar")
end


puts "Success!"
