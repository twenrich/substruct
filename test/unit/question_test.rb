require File.dirname(__FILE__) + '/../test_helper'

class QuestionTest < Test::Unit::TestCase
  fixtures :questions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Question, questions(:first)
  end
end
