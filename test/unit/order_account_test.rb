require File.dirname(__FILE__) + '/../test_helper'

class OrderAccountTest < ActiveSupport::TestCase
  fixtures :order_accounts, :order_users


  # Test if a valid account can be created with success.
  def test_should_create_account
    an_account = OrderAccount.new
    
    an_account.order_user = order_users(:mustard)
    an_account.cc_number = "|
    LzmzOb/JS+mFF72xts17cg==
"
    an_account.routing_number = ""
    an_account.bank_name = ""
    an_account.expiration_year = 2012
    an_account.expiration_month = 1
    an_account.credit_ccv = ""
    an_account.account_number = ""

    assert an_account.save
  end


  # Test if an account can be found with success.
  def test_should_find_account
    an_account_id = order_accounts(:santa_account).id
    assert_nothing_raised {
      OrderAccount.find(an_account_id)
    }
  end


  # Test if an account can be updated with success.
  def test_should_update_account
    an_account = order_accounts(:santa_account)
    assert an_account.update_attributes(:expiration_month => 2)
  end


  # Test if an account can be destroyed with success.
  def test_should_destroy_account
    an_account = order_accounts(:santa_account)
    an_account.destroy
    assert_raise(ActiveRecord::RecordNotFound) {
      OrderAccount.find(an_account.id)
    }
  end


  # Test if an invalid account really will NOT be created.
  def test_should_not_create_invalid_account
    an_account = OrderAccount.new
    
    assert !an_account.valid?
    assert an_account.errors.invalid?(:expiration_month), "Should have an error in expiration_month"
    assert an_account.errors.invalid?(:expiration_year), "Should have an error in expiration_year"
    
    # An address must have the fields filled.
    assert_same_elements ["is not a number", "Please enter a valid expiration date."], an_account.errors.on(:expiration_month)
    assert_equal "is not a number", an_account.errors.on(:expiration_year)

    an_account.order_account_type_id = OrderAccount::TYPES['Credit Card']
    assert !an_account.valid?
    assert an_account.errors.invalid?(:cc_number)
 
    # An account of type "Credit Card" must have a cc_number.
    assert_equal ERROR_EMPTY, an_account.errors.on(:cc_number)
 
    an_account.order_account_type_id = OrderAccount::TYPES['Checking']
    assert !an_account.valid?
    assert an_account.errors.invalid?(:routing_number)
    assert an_account.errors.invalid?(:account_number)
 
    # An account of type "Checking" must have a routing_number and an account_number.
    assert_equal ERROR_EMPTY, an_account.errors.on(:routing_number)
    assert_equal ERROR_EMPTY, an_account.errors.on(:account_number)

    assert !an_account.save
  end


  # TODO: Verify if this method is used.
  # Test if a shipping address can be found for an user.
  def dont_test_should_find_shipping_address
    # find_shipping_address_for_user appears to be a deprecated method, as when
    # executed it gives an error, and I couldn't find an ocasion where it will be executed.
    assert_raise(ActiveRecord::StatementInvalid) {
      OrderAccount.find_shipping_address_for_user(users(:c_norris))
    }
  end


  # Test if the user's first and last name will be concatenated.
  def dont_test_should_concatenate_user_first_and_last_name
    an_address = order_accountes(:santa_address)
    assert_equal an_address.name, "#{an_address.first_name} #{an_address.last_name}" 
  end


end
