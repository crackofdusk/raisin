class AssertionError < StandardError
end

module Assertions
  def assert(condition, failure_reason = nil)
    unless condition
      raise AssertionError, failure_reason
    end
  end

  def assert_equal(expected, actual)
    message = "Expected #{expected.inspect}, got #{actual.inspect}"
    assert(expected == actual, message)
  end
end

class TestSuite
  include Assertions

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
    report.summarize
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
    rescue AssertionError => error
      TestFailure.new(error)
    end
  end
end

class TestSuccess
  def success?
    true
  end
end

class TestFailure
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def success?
    false
  end
end

class Report
  attr_reader :runs

  def initialize(io)
    @io = io
    @runs = 0
    @errors = []
  end

  def add_result(result)
    if result.success?
      io.print "."
    else
      @errors << result.error
      io.print "F"
    end
    @runs = @runs + 1
  end

  def failures
    @errors.count
  end

  def summarize
    io.puts
    @errors.each do |failure|
      io.puts
      io.puts failure.message
      io.puts failure.backtrace
      io.puts
    end
    io.puts
    io.puts "#{runs} runs, #{failures} failures"
  end

  private

  attr_accessor :io
end
