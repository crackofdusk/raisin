require 'optparse'

module Raisin
  @@at_exit_registered ||= false

  def self.autorun
    unless @@at_exit_registered
      at_exit { Raisin.run(ARGV) }
      @@at_exit_registered = true
    end
  end

  def self.run(args)
    options = RunOptions.parse(args)
    TestSuite.run(options)
  end

  class RunOptions
    attr_reader :seed

    def self.parse(arguments = [])
      program_options = {}

      parser = OptionParser.new do |options|
        options.on('-h', '--help', 'Display this help') do
          puts options
          exit
        end

        options.on('--seed SEED', Integer, 'Set random seed') do |value|
          program_options[:seed] = value.to_i
        end
      end

      parser.parse!(arguments)

      new(program_options.fetch(:seed, Random.new_seed))
    end

    def invocation_command
      ['ruby', $PROGRAM_NAME, '--seed', seed].join(" ")
    end

    private

    def initialize(seed)
      @seed = seed
    end
  end

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

    def self.unregister(suite)
      @suites.delete(suite)
    end

    def self.run(io = $stdout, options)
      report = Report.new(io, options)

      @suites.each do |suite|
        suite.new.run(report, options)
      end

      report.summarize
    end

    def run(report, options)
      test_names = public_methods(false).grep(/^test_/)

      test_names.shuffle(random: Random.new(options.seed)).each do |test|
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

    def initialize(io, options)
      @io = io
      @runs = 0
      @errors = []
      @options = options
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
        io.puts filter(failure.backtrace)
        io.puts
      end
      io.puts
      io.puts "#{runs} runs, #{failures} failures"
      io.puts
      io.puts 'Rerun the tests in the same order with:'
      io.puts options.invocation_command
    end

    private

    def filter(backtrace)
      backtrace.reject { |line| line =~ /lib\/raisin/ }
    end

    attr_accessor :io
    attr_reader :options
  end
end
