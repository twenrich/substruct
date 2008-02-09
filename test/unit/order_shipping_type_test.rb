require File.dirname(__FILE__) + '/../test_helper'

class OrderShippingTypeTest < Test::Unit::TestCase
  fixtures :order_shipping_types
  
  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderShippingType, OrderShippingType.find(:first)
  end

  # Makes sure we get domestic shipping types
  def test_get_domestic
    @shipping_types = OrderShippingType.get_domestic
    @shipping_types.each { |type|
      assert type.is_domestic
    }
  end

  # Makes sure we get foreign order shipping types
  def test_get_foreign
    @shipping_types = OrderShippingType.get_foreign
    @shipping_types.each { |type|
      assert !type.is_domestic
    }
  end

  # Makes sure that we can calculate a price for shipping type
  def test_get_price
    @type = OrderShippingType.find(:first)
    assert_not_nil @type.calculate_price(2)
  end

end
