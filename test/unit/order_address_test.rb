require File.dirname(__FILE__) + '/../test_helper'

class OrderAddressTest < Test::Unit::TestCase
  fixtures :order_addresses, :order_users

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderAddress, order_addresses(:first)
  end

  def test_find_shipping_address
    @joe = order_users(:joe)
    @shipping_address = OrderAddress.find_shipping_address_for_user(@joe)
    assert_kind_of OrderAddress, @shipping_address
    assert_equal @shipping_address.is_shipping, true
  end

  def test_validate
    @bad_address = order_addresses(:bobs_bad_address)
    @bad_address.valid?
    assert_equal @bad_address.errors.blank?, false

    @good_address = order_addresses(:bobs_address)
    @good_address.valid?
    assert_equal @good_address.errors.blank?, true
  end

end
