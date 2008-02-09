require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < Test::Unit::TestCase
  fixtures :countries

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Country, Country.find(:first)
  end

  def test_usa_exists
    @country = Country.find(1)
    assert_equal 'United States of America', @country.name
  end
end
