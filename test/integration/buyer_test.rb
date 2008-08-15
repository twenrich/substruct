require File.dirname(__FILE__) + '/../test_helper'

class BuyerTest < ActionController::IntegrationTest
  fixtures :orders, :order_line_items, :order_addresses, :order_users, :order_shipping_types, :items
  fixtures :order_accounts, :order_status_codes, :countries, :promotions, :preferences, :wishlist_items
  fixtures :tags


  def test_should_buy_something




    # LOGIN TO THE SYSTEM
    a_customer = order_users(:santa)

    get 'customers/login'
    assert_response :success
    assert_equal assigns(:title), "Customer Login"
    assert_template 'login'
    
    post 'customers/login', :modal => "", :login => "santa.claus@whoknowswhere.com", :password => "santa"
    # If loged in we should be redirected to orders. 
    assert_response :redirect
    assert_redirected_to :action => :orders
    
    # We need to follow the redirect.
    follow_redirect!
    assert_select "p", :text => /Login successful/

    # Assert the customer id is in the session.
    assert_equal session[:customer], a_customer.id

  
  
  
    # ADD 1 PRODUCT TO THE CART

    # Try adding a product.
    a_product = items(:towel)
    post 'store/add_to_cart_ajax', :id => a_product.id
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1



    
    # CHECKOUT AND FOLLOW
    
    get 'store/checkout'
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    ###################
    a_cart = assigns(:cart)
    assert_equal a_cart.items.first.quantity, 1, "UNEXPECTED FIRST CART ITEM QUANTITY"
    ###################

    # Post to it an order.
    post 'store/checkout',
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :billing_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    },
    :use_separate_shipping_address => "false"
    
    assert_response :redirect
    assert_redirected_to :action => :select_shipping_method

    ###################
    an_order = assigns(:order)
    assert_equal an_order.items.first.quantity, 1, "UNEXPECTED FIRST ORDER ITEM QUANTITY AFTER CHECKOUT"
    ###################

    follow_redirect!

    # Verify is was followed.
    assert_response :success
    assert_template 'select_shipping_method'
    assert_equal assigns(:title), "Select Your Shipping Method - Step 2 of 3"
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:default_price)
    
    
    
    
    # SET THE SHIPPING METHOD AND FOLLOW
    
    # Post to it when the show confirmation preference is true.
    assert Preference.save_settings({ "store_show_confirmation" => "1" })
    post 'store/set_shipping_method', :ship_type_id => order_shipping_types(:ups_ground).id
    assert_response :redirect
    assert_redirected_to :action => :confirm_order

    ###################
    an_order = assigns(:order)
    assert_equal an_order.items.first.quantity, 1, "UNEXPECTED FIRST ORDER ITEM QUANTITY AFTER SHIPPING"
    ###################

    follow_redirect!

    # Verify is was followed.
    assert_template 'confirm_order'
    assert_equal assigns(:title), "Please confirm your order. - Step 3 of 3"
    
    
    
    
    # SECOND ITERACTION
    


    
    # ADD 1 MORE PRODUCT TO THE CART

    # Try adding a product.
    a_product = items(:towel)
    post 'store/add_to_cart_ajax', :id => a_product.id
    # Here nothing is rendered directly, but a showPopWin() javascript function is executed.
    a_cart = assigns(:cart)
    assert_equal a_cart.items.length, 1
    
    ###################
    a_cart = assigns(:cart)
    assert_equal a_cart.items.first.quantity, 2, "UNEXPECTED SECOND CART ITEM QUANTITY"
    ###################




    # CHECKOUT THE SECOND TIME AND FOLLOW
    
    get 'store/checkout'
    assert_response :success
    assert_template 'checkout'
    assert_equal assigns(:title), "Please enter your information to continue this purchase."
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:cc_processor)
    
    # Post to it an order.
    post 'store/checkout',
    :order_account => {
      :cc_number => "4007000000027",
      :expiration_year => 4.years.from_now.year,
      :expiration_month => "1"
    },
    :shipping_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :billing_address => {
      :city => "North Pole",
      :zip => "00000",
      :country_id => countries(:US).id,
      :first_name => "Santa",
      :telephone => "000000000",
      :last_name => "Claus",
      :address => "After second ice mountain at left",
      :state => "Alaska"
    },
    :order_user => {
      :email_address => "uncle.scrooge@whoknowswhere.com"
    },
    :use_separate_shipping_address => "false"
    
    ###################
    a_cart = assigns(:cart)
    assert_equal a_cart.items.first.quantity, 2, "UNEXPECTED SECOND CART ITEM QUANTITY AFTER CHECKOUT"
    ###################
    an_order = assigns(:order)
    assert_equal an_order.items.first.quantity, 2, "UNEXPECTED SECOND ORDER ITEM QUANTITY AFTER CHECKOUT"
    ###################

    assert_response :redirect
    assert_redirected_to :action => :select_shipping_method

    follow_redirect!
    
    # Verify is was followed.
    assert_response :success
    assert_template 'select_shipping_method'
    assert_equal assigns(:title), "Select Your Shipping Method - Step 2 of 3"
    assert_not_nil assigns(:items)
    assert_not_nil assigns(:default_price)
    
    
    
    
    # SET THE SHIPPING METHOD THE SECOND TIME AND FOLLOW
    
    # Post to it when the show confirmation preference is true.
    assert Preference.save_settings({ "store_show_confirmation" => "1" })
    post 'store/set_shipping_method', :ship_type_id => order_shipping_types(:ups_ground).id
    assert_response :redirect
    assert_redirected_to :action => :confirm_order

    follow_redirect!

    # Verify is was followed.
    assert_template 'confirm_order'
    assert_equal assigns(:title), "Please confirm your order. - Step 3 of 3"
    
    

  end


end
