require 'optparse'

# :include: README.rdoc
module Raisin
  @@at_exit_registered ||= false # :nodoc:

  # Sets up tests to run before the process exits
  def self.autorun
    unless @@at_exit_registered
      at_exit { Raisin.run(ARGV) }
      @@at_exit_registered = true
    end
  end

  # Runs all registered test suites
  #
  # +args+:: command line arguments
  def self.run(args)
    options = RunOptions.parse(args)
    TestSuite.run(options)
  end

  # Parameters for running the tests
  class RunOptions
    # Random seed used to determine in which order the tests will run
    attr_reader :seed

    # Parses command line arguments
    #
    # +arguments+:: array of command line options
    #
    # Returns an object containing the desired program state
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

    # String representation of the shell command that will reproduce the current
    # test run
    def invocation_command
      ['ruby', $PROGRAM_NAME, '--seed', seed].join(" ")
    end

    private

    def initialize(seed)
      @seed = seed
    end
  end

  # Represents test failures
  class AssertionError < StandardError
  end

  # Test assertions
  #
  # Adding assertion methods to this module makes them available to all tests
  module Assertions
    # Fails unless +condition+ is true
    def assert(condition, failure_reason = nil)
      unless condition
        raise AssertionError, failure_reason
      end
    end

    # Fails unless <tt>expected == actual</tt>
    def assert_equal(expected, actual)
      message = "Expected #{expected.inspect}, got #{actual.inspect}"
      assert(expected == actual, message)
    end
  end

  # A collection of tests
  #
  # Subclasses of +TestSuite+ group related tests and are ran by Raisin
  class TestSuite
    include Assertions

    @suites = [] # :nodoc:

    def self.inherited(suite) # :nodoc:
      @suites << suite
    end

    def self.unregister(suite) # :nodoc:
      @suites.delete(suite)
    end

    # Runs all Raisin test suites, reporting progress and test results
    def self.run(io = $stdout, options)
      report = Report.new(io, options)

      @suites.each do |suite|
        suite.new.run(report, options)
      end

      report.summarize
    end

    # Runs all tests in the test suite, recording their results
    #
    # Tests are all methods whose names start with +test_+.
    #
    # +report+:: where the test results are stored. Must conform to same API as +Report+
    # +options+:: See +RunOptions+
    #
    # Returns the report with appended results from this test suite
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

    # Runs before each test
    #
    # Override to add custom test setup
    def setup
    end

    # Runs after each test
    #
    # Override to add custom test cleanup
    def teardown
    end
  end

  class TestResult # :nodoc:
    def self.from(&block)
      begin
        yield
        TestSuccess.new
      rescue AssertionError => error
        TestFailure.new(error)
      end
    end
  end

  class TestSuccess # :nodoc:
    def success?
      true
    end
  end

  class TestFailure # :nodoc:
    attr_reader :error

    def initialize(error)
      @error = error
    end

    def success?
      false
    end
  end

  # A record of the results of executed tests
  #
  # The same report can be reused between test suites. It will accumulate their
  # results.
  class Report
    # Total number of tests
    attr_reader :runs

    # +io+:: output stream for the report
    # +options+:: see +RunOptions+
    def initialize(io, options)
      @io = io
      @runs = 0
      @errors = []
      @options = options
    end

    # Records the result of a single test
    def add_result(result)
      if result.success?
        io.print "."
      else
        errors << result.error
        io.print "F"
      end
      self.runs = runs + 1
    end

    # Number of failed tests
    def failures
      errors.count
    end

    # Prints error messages of failing tests and a summary of all accumulated
    # test results
    #
    # To be called after all tests have finished running
    def summarize
      print_errors
      print_totals
      print_invocation_command
    end

    private

    def filter(backtrace)
      backtrace.reject { |line| line =~ /lib\/raisin/ }
    end

    def print_errors
      io.puts
      errors.each do |failure|
        io.puts
        io.puts failure.message
        io.puts filter(failure.backtrace)
        io.puts
      end
      io.puts
    end

    def print_totals
      io.puts "#{runs} runs, #{failures} failures"
      io.puts
    end

    def print_invocation_command
      io.puts 'Rerun the tests in the same order with:'
      io.puts options.invocation_command
    end

    attr_accessor :io, :errors
    attr_reader :options
    attr_writer :runs
  end
end
