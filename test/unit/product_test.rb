require File.dirname(__FILE__) + '/../test_helper'

class ProductTest < Test::Unit::TestCase
  fixtures :products

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Product, products(:soap)
  end
end
