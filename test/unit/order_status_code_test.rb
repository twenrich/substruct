require File.dirname(__FILE__) + '/../test_helper'

class OrderStatusCodeTest < Test::Unit::TestCase
  fixtures :order_status_codes

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderStatusCode, OrderStatusCode.find(1)
  end
end
