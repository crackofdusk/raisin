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

  def run(io = $stdout)
    report = Report.new(io)
    test_names = public_methods(false).grep(/^test_/)

    test_names.each do |test|
      result = TestResult.from do
        setup
        send(test)
        teardown
      end
      report.add_result(result)
    end
    report
  end

  def setup
  end

  def teardown
  end
end

class TestResult
  def self.from(&block)
    begin
      yield
      TestSuccess.new
    rescue AssertionError
      TestFailure.new
    end
  end
end

class TestSuccess
  def success?
    true
  end
end

class TestFailure
  def success?
    false
  end
end

class Report
  attr_reader :runs, :failures

  def initialize(io)
    @io = io
    @runs = 0
    @failures = 0
  end

  def add_result(result)
    if result.success?
      io.print "."
    else
      @failures = @failures + 1
      io.print "F"
    end
    @runs = @runs + 1
  end

  private

  attr_accessor :io
end

class DummySuite < TestSuite
  def test_equality
    assert_equal(1, 2) # should fail
  end

  def test_the_truth
    assert(true)
  end
end

output = StringIO.new
report = DummySuite.new.run(output)
assert_equal(2, report.runs)
assert_equal(1, report.failures)
assert_equal("F.", output.string)

puts "Success!"
