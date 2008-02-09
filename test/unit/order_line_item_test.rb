require File.dirname(__FILE__) + '/../test_helper'

class OrderLineItemTest < Test::Unit::TestCase
  fixtures :order_line_items

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderLineItem, order_line_items(:first)
  end
end
