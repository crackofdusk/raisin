require_relative './raisin'

class NothingRaised < StandardError
end

class AssertionTests < TestSuite
  def test_true
    assert(true)
  end

  def test_truthy
    assert("")
    assert([])
    assert("foo")
    assert(Object.new)
  end

  def test_false
    assert_error { assert(false) }
  end

  def test_falsy
    assert_error { assert(nil) }
  end

  def test_equal
    assert_equal("foo", 'foo')
    assert_equal(1, 1)
  end

  def test_not_equal
    assert_error { assert_equal(1, 2) }
    assert_error { assert_equal("foo", "bar") }
  end

  def assert_error(&block)
    raised = false
    begin
      yield
    rescue AssertionError
      raised = true
    end
    raise NothingRaised unless raised
  end
end

AssertionTests.new.run


class ReportingTests < TestSuite
  def test_statistics
    suite = Class.new(TestSuite) do
      def test_equality
        assert_equal(1, 2)
      end

      def test_the_truth
        assert(true)
      end
    end

    output = StringIO.new
    report = suite.new.run(output)
    assert_equal(2, report.runs)
    assert_equal(1, report.failures)
    assert(output.string.include?("2 runs, 1 failures"),
           "Report does not include statistics")
  end

  def test_summary
    suite = Class.new(TestSuite) do
      def test_1
        assert(false, "failure1")
      end

      def test_2
        assert(false, "failure2")
      end
    end
    output = StringIO.new
    suite.new.run(output)
    assert(output.string.include?("failure1"),
           "Report does not include error details")
    assert(output.string.include?("failure2"),
           "Report does not include error details")
  end
end

ReportingTests.new.run
