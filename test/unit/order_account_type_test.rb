require File.dirname(__FILE__) + '/../test_helper'

class OrderAccountTypeTest < Test::Unit::TestCase
  fixtures :order_account_types

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderAccountType, order_account_types(:first)
  end
end
