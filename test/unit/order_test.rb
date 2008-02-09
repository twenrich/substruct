require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < Test::Unit::TestCase
  fixtures :orders, :countries, :order_shipping_types, :order_status_codes,
           :order_users, :order_addresses, :products, :order_line_items,
           :order_accounts

  def setup
    @order = orders(:valid_order)
		@bad_order = orders(:invalid_order)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Order, orders(:first)
  end

  def test_valid_orders
    assert_not_nil orders(:valid_order)
    assert_not_nil orders(:old_order)
    @old_order_db = Order.find(orders(:old_order)['id'])
    assert_not_nil @old_order_db
    assert_equal orders(:old_order)['product_cost'], @old_order_db.product_cost
  end

  #  Searches for an order using order number
  def test_search
    @orders = Order.search(@order['order_number'])
    @orders.each { |order|
      assert_equal @order['order_number'], order.order_number
    }
  end

  def test_generate_order_number
    assert_not_nil Order.generate_order_number()
  end

  # Tests that we can get totals for the year 2000.
  def test_get_totals
    @old_order = orders(:old_order)
    @totals = Order.get_totals_for_year(2000)
    assert_kind_of Array, @totals
    assert_equal 13, @totals.length
    assert_equal @old_order['product_cost'], @totals[0]['sales_total']
    assert_equal @old_order['tax'], @totals[0]['tax']
    assert_equal @old_order['shipping_cost'], @totals[0]['shipping']
  end

  # Can we get XML for our orders?
  def test_get_xml_for_orders
    @orders = Order.find(:all, :conditions => 'order_status_code_id = 5')
    @xml = Order.get_xml_for_orders(@orders)
    assert_kind_of String, @xml
  end

  # What's the order status
  def test_status
    @order_status = OrderStatusCode.find(@order['order_status_code_id'])
    assert_equal @order_status.name, @order.status
  end

  # Accessor for line items
  def test_items
    assert_equal @order.items, @order.order_line_items
  end

  # Total for the order
  def test_total
    assert_equal @order.total, (@order.line_items_total + @order.shipping_cost)
  end

  def test_account
    assert_equal @order.account, @order.order_user.order_account
  end

  def test_billing_address
		assert_equal @order.billing_address, @order.order_user.order_account.order_address
  end

  def test_shipping_address
    assert_equal @order.shipping_address, OrderAddress.find_shipping_address_for_user(@order.order_user)
  end

  # Can we assign line items for an order by passing in a hash of product id's
  # and quantities?
  # This comes from posts all over the app.
  def test_line_items
    @products = {'1' => {'quantity' => 1} }
    @order.line_items = @products
    # Test adding one line item
    assert_equal @order.order_line_items.length, 1
    assert_equal @order.get_line_item_quantity(1), 1
    # Test adding one line item with a bigger quantity
    @products['1'] = {'quantity' => 2}
    @order.line_items = @products
    # Test some of our other line item methods
    assert_equal @order.has_line_item?(1), true
    assert_equal @order.has_line_item?(2), false
    assert_equal @order.get_line_item_quantity(1), 2
		# Assert money is correct
		@soap = Product.find(1)
		assert_equal @order.get_line_item_total(1), (@soap.price*2)
		# Is the total correct?
		assert_equal @order.line_items_total, (@soap.price*2)
		# Reset all line items
		@order.line_items = {}
		assert_equal @order.order_line_items.length, 0
  end

  # Grabs the total amount of all line items associated with this order
  def test_line_items_total
    total = 0
    for item in @order.order_line_items
      total += item.total
    end
    assert_equal @order.line_items_total, total
  end

	def test_weight
		weight = 0
		@order.order_line_items.each do |item|
			weight += item.quantity * item.product.weight
		end
		assert_equal @order.weight, weight
	end

	# Connects to FedEx to get shipping prices!
	def test_get_prices
		assert_nothing_raised() {
			@prices = @order.get_shipping_prices
			assert_not_nil @prices
			assert_kind_of Array, @prices

		}
	end

	# Checks connectivity to Authorize.net.
	# Uses a valid credit card number found here:
	# 	http://developer.authorize.net/faqs/#7429
	def test_valid_transaction
		assert_nothing_raised() {
			@transaction = @order.get_auth_transaction
			assert_equal @transaction.test_transaction, true
			@transaction.submit
		}
	end
	# Send through a transaction with a bad credit card number
	def test_invalid_transaction
		assert_raise(Payment::PaymentError) {
			@transaction = @bad_order.get_auth_transaction
			assert_equal @transaction.test_transaction, true
			@transaction.submit
		}
	end

  # Cleaning up orders after they're done
	def test_cleanup_successful
		@order.cleanup_successful
		assert_equal @order.order_status_code_id, 5
	  assert_equal @order.notes.include?("Order completed."), true
	  assert_equal @order.product_cost, @order.line_items_total
	end
	def test_cleanup_failed
    failure_string = 'Sorry man your credit card was declined.'
		@order.cleanup_failed(failure_string)
		assert_equal @order.order_status_code_id, 3
		assert_equal @order.notes.include?("Order failed!"), true
		assert_equal @order.notes.include?(failure_string), true
	end

  # Make sure search works
  def test_search
    @search_order = Order.search(order_addresses(:joes_address)['first_name'])
    assert_not_nil @search_order
  end

end
