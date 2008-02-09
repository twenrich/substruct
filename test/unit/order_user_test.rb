require File.dirname(__FILE__) + '/../test_helper'

class OrderUserTest < Test::Unit::TestCase
  fixtures :order_users

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderUser, order_users(:joe)
  end
end
