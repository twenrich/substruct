class OrderAccount < ActiveRecord::Base
  # Associations
	has_one :order_account_type
  has_one :order
  belongs_to :order_user
  # Validation
	validates_presence_of :order_user_id
	validates_length_of :cc_number, :maximum => 20
	#validates_length_of :routing_number, :in => 0..9
	#validates_length_of :account_number, :maximum => 20
	# Make sure these are only numbers
  validates_format_of :cc_number, :with => /^[\d]*$/,
                      :message => ERROR_NUMBER
  #validates_format_of :account_number, :with => /^[\d]*$/,
  #                    :message => ERROR_NUMBER
  validates_format_of :credit_ccv, :with => /^[\d]*$/,
                      :message => ERROR_NUMBER
  #validates_format_of :routing_number, :with => /^[\d]*$/,
  #                    :message => ERROR_NUMBER
	validates_numericality_of :expiration_month, :expiration_year

	# Make sure expiration date is ok.
	def validate
		today = DateTime.now
		if (today.month > self.expiration_month && today.year >= self.expiration_year)
			errors.add(:expiration_month, 'Please enter a valid expiration date.')
		end

		# Add errors for credit card accounts
		if ((self.order_account_type_id == nil || self.order_account_type_id == 1) && self.cc_number.blank?)
		  errors.add(:cc_number, ERROR_EMPTY)
		end

		# Add errors for account type checking
		if (self.order_account_type_id == 2 || self.order_account_type_id == 4)
		  if (self.routing_number.blank?)
		    errors.add(:routing_number, ERROR_EMPTY)
	    end
	    if (self.account_number.blank?)
		    errors.add(:account_number, ERROR_EMPTY)
	    end
		end
	end

	# List of months for dropdown in UI
  def self.months
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  end

  # List of years for dropdown in UI
  def self.years
    start_year = Date.today.year
    years = Array.new
		10.times do
      years << start_year
      start_year += 1
    end
    return years
  end

  # Obfuscates personal information about this account
  # - CC number
  def clear_personal_information
		number = String.new(self.cc_number)
		# How many spaces to replace with X's
		spaces_to_pad = number.length-4
		# Cut string
		new_number = number[spaces_to_pad,number.length]
		# Pad with X's
		new_number = new_number.rjust(spaces_to_pad, 'X')
		self.cc_number = new_number
		self.save
		# Return number in case we need it
		return new_number
  end

end
