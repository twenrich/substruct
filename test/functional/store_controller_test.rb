require File.dirname(__FILE__) + '/../test_helper'

class StoreControllerTest < ActionController::TestCase
  fixtures :orders, :order_line_items, :order_addresses, :order_users, :order_shipping_types, :items
  fixtures :order_accounts, :order_status_codes, :countries, :promotions, :preferences, :wishlist_items
  fixtures :tags


  # Test the index action.
  def test_should_show_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_equal assigns(:title), "Store"
    assert_not_nil assigns(:tags)
    assert_not_nil assigns(:products)
  end


  # We should get a list of products using a search term.
  def test_should_search
    a_term = "an"
    get :search, :search_term => a_term
    assert_response :success
    assert_equal assigns(:title), "Search Results for: #{a_term}"
    # It should only list products, not variations.
    assert assigns(:products)
    assert_equal assigns(:products).size, 2
    assert_template 'index'


    # Now with a term, that returns only one result.
    a_term = "lightsaber"
    get :search, :search_term => a_term
    assert_response :redirect
    assert_redirected_to :action => :show
    assert assigns(:products)
    assert_equal assigns(:products).size, 1
    
    follow_redirect
    assert_equal assigns(:title), assigns(:products)[0].name
  end


  # We should get a list of products that belongs to a tag.
  def test_should_show_by_tags
    # Call it first without a tag.
    get :show_by_tags, :tags => ""
    assert_response :missing


    # Now call it again with a tag.
    a_tag = tags(:weapons)
    get :show_by_tags, :tags => a_tag.name
    assert_response :success
    assert_equal assigns(:title), "Store #{assigns(:viewing_tags).collect { |t| ' > ' + t.name}}"
    assert assigns(:products)
    assert_template 'index'


    # Call it again with an invalid tag.
    get :show_by_tags, :tags => "invalid"
    assert_response :missing
  end


  # Test the display_product.
  def test_should_display_product
    # TODO: If this method is not used anymore, get rid of it.
    a_product = items(:lightsaber)
    another_product = items(:uranium_portion)
    
    # Get the result of one product that have images.
    get :display_product, :id => a_product.id
    # Get the result of one product that don't have images.
    get :display_product, :id => another_product.id
  end
  
  
  # Test the show action.
  def test_should_show_show
    a_product = items(:lightsaber)
    
    # TODO: A code is being passed to a hash parameter called id.
    get :show, :id => a_product.code
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:product)
    assert_equal assigns(:title), a_product.name
    assert_equal assigns(:variations).size, 3


    # Now with an invalid code.
    get :show, :id => "invalid"
    assert_response :redirect
    assert_redirected_to :action => :index
    follow_redirect
    assert_select "p", :text => /Sorry, we couldn/
  end
  
  
  # Test the show cart action. This is the action that shows the modal cart.
  def test_should_show_cart
    get :show_cart
    
    # Here we get as a response an entire html page to render inside a modal layout.
    # puts @response.body
  end

end
