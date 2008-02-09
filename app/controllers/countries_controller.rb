class CountriesController < ApplicationController

	# Build a select list of countries, but make sure the USA is first
  def select_list
    @select_name = params[:select_name]
    @selected = params[:selected]
		usa_name = 'United States of America'
		@usa = Country.find(:first, :conditions => ["name = ?", usa_name])
    @countries = Country.find(:all,
                              :conditions => ['fedex_code IS NOT NULL AND name <> ?', usa_name],
                              :order => 'name ASC')
		@countries.insert(0, @usa)
  end
end
