require File.dirname(__FILE__) + '/../test_helper'

class OrderAccountTest < Test::Unit::TestCase
  fixtures :order_accounts

  def setup
    @joes_account = order_accounts(:joes_account)
    @bobs_account = order_accounts(:bobs_account)
    @invalid_account = order_accounts(:invalid_account)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of OrderAccount, order_accounts(:first)
  end

  # Testing valid account
  def test_valid_account
    @joes_account.valid?
    assert_equal @joes_account.errors.blank?, true
  end
  # Test invalid account
  def test_invalid_account
    @invalid_account.valid?
    assert_equal @invalid_account.errors.blank?, false
  end

  def test_months
    assert_kind_of Array, OrderAccount.months
    assert_equal OrderAccount.months.length, 12
  end
  def test_years
    assert_kind_of Array, OrderAccount.years
    assert_equal OrderAccount.years.length, 10
  end

  # Make sure we clear personal info
  def test_clear_personal_info
    @old_cc_number = @joes_account.cc_number
    @joes_account.clear_personal_information
    assert_not_equal @old_cc_number, @joes_account.cc_number
  end

end
