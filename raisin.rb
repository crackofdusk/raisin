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

class TestSuite
  @suites = []

  def self.inherited(suite)
    @suites << suite
  end

  def self.run
    @suites.each do |suite|
      suite.new.run
    end
  end

  def run
    test_names = public_methods(false).grep(/^test_/)

    test_names.each do |test|
      setup
      send(test)
      teardown
    end
  end

  def setup
  end

  def teardown
  end
end

def greet(name = nil)
  ['Hello', name].compact.join(", ") + "!"
end

class GreetingTestSuite < TestSuite
  def test_with_name
    assert_equal("Hello, Bob!", greet("Bob"))
  end

  def test_without_name
    assert_equal("Hello!", greet)
  end
end

GreetingTestSuite.new.run


puts "Success!"
