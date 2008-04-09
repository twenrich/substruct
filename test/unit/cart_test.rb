require File.dirname(__FILE__) + '/../test_helper'

class CartTest < ActiveSupport::TestCase
  fixtures :items


  # When created the cart should be empty.
  def test_when_created_should_be_empty
    a_cart = Cart.new
    
    assert_equal a_cart.items, []
    assert_equal a_cart.tax, 0.0
    assert_equal a_cart.total, 0.0
    assert_equal a_cart.shipping_cost, 0.0
  end


  # Test if a product can be added to the cart.
  def test_should_add_product
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 1)
    assert_equal a_cart.items.length, 1
  end


  # Test if a product can be removed from the cart.
  def test_should_remove_product
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 2)
    a_cart.add_product(items(:blue_lightsaber), 2)
    # Repeat the same product again.
    a_cart.add_product(items(:blue_lightsaber), 2)
    assert_equal a_cart.items.length, 2
    # When not specified a quantity all units from the product will be removed.
    a_cart.remove_product(items(:blue_lightsaber))
    assert_equal a_cart.items.length, 1
    # When specified a quantity, just these units from the product will be removed.
    a_cart.remove_product(items(:red_lightsaber), 1)
    assert_equal a_cart.items.length, 1
    # It should not be empty.
    assert !a_cart.empty?
    # Now it should be empty.
    a_cart.remove_product(items(:red_lightsaber), 1)
    assert a_cart.empty?
  end


  # Test if what is in the cart is really available in the inventory.
  def test_should_check_inventory
    # Create a cart and add some products.
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 2)
    a_cart.add_product(items(:blue_lightsaber), 4)
    assert_equal a_cart.items.length, 2
    
    an_out_of_stock_product = items(:red_lightsaber)
    assert an_out_of_stock_product.update_attributes(:quantity => 1)
    
    # Assert that the product that was out of stock was removed.
    removed_products = a_cart.check_inventory
    assert_equal removed_products, [an_out_of_stock_product.name]

    # Should last the right quantity of the rest.
    assert_equal a_cart.items.length, 1
  end
  
  
  # Test if will return the total price of products in the cart.
  def test_should_return_total_price
    # Create a cart and add some products.
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 2)
    a_cart.add_product(items(:blue_lightsaber), 4)
    assert_equal a_cart.items.length, 2

    total = 0.0
    for item in a_cart.items
      total += (item.quantity * item.unit_price)
    end

    assert_equal total, a_cart.total
  end


  # Test if will return the tax cost for the total in the cart.
  def test_should_return_tax_cost
    # Create a cart and add some products.
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 2)
    a_cart.add_product(items(:blue_lightsaber), 4)
    
    # By default tax is zero.
    assert_equal a_cart.tax_cost, a_cart.total * a_cart.tax
  end


  # Test if will return the line items total.
  def test_should_return_line_items_total
    # Create a cart and add some products.
    a_cart = Cart.new
    a_cart.add_product(items(:red_lightsaber), 2)
    a_cart.add_product(items(:blue_lightsaber), 4)
    
    assert_equal a_cart.line_items_total, a_cart.total
  end


end
