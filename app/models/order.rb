class Order < ActiveRecord::Base  
  # Associations
  has_many :order_line_items, :dependent => :destroy
  # billing_address defined as a method!
  belongs_to :billing_address, 
    :class_name => 'OrderAddress',
    :foreign_key => 'billing_address_id'
  belongs_to :shipping_address,
    :class_name => 'OrderAddress',
    :foreign_key => 'shipping_address_id'
  belongs_to :order_account
  belongs_to :order_user
  belongs_to :order_shipping_type
  belongs_to :order_status_code
  belongs_to :promotion

	attr_accessor :promotion_code

  # VALIDATION ================================================================

	# Validation
	validates_presence_of :order_number
	validates_uniqueness_of :order_number


  # CALLBACKS =================================================================
  
  # Sets product cost based on line items total before a save.
  before_save :set_product_cost
  def set_product_cost
    self.product_cost = self.line_items_total
  end
  
  # Modifies the order based on any promotion codes passed in.
  #
  # This can add discounts to the order or add items.
  #
  # Returns silently and just doesn't add the promo if something
  # is wrong.
  #
  before_save :set_promo_code
  def set_promo_code
    # Find promotion based on code entered
    promo = Promotion.find(
      :first,
      :conditions => ["code = ?", self.promotion_code]
    )
    # No promo code? Not active? No deal...
    return if !promo || !promo.is_active?
    
    # Make sure it's valid to add
    if promo.minimum_cart_value
      return if promo.minimum_cart_value > self.total
    end
    logger.info "PROMO MIN CART VALUE PASSED"
    
    # Don't allow more than one promotion?
    # This destroys any line items created previously.
    self.promotion_line_item.destroy if self.promotion_line_item
    
    # Assign proper promotion ID
    self.promotion_id = promo.id
    
    # Add any line items necessary from promotion.
    oli = OrderLineItem.new
    logger.info "CREATED OLI"
    # Set name & item...
    oli.name = promo.description
    oli.item_id = promo.item_id
    
    # Figure out how to apply the promotion
    case promo.discount_type
      # Dollars
      when 0 then
        oli.quantity = 1
        oli.unit_price = -promo.discount_amount
      #
      # Percent
      when 1 then
        oli.quantity = 1
        oli.unit_price = -(self.total * (promo.discount_amount/100))
      #
      # Buy N get 1 free
      when 2 then
        item = self.order_line_items.detect { |i| i.item_id == promo.item_id }
        if item && item.quantity >= promo.discount_amount.to_i
          oli.quantity = item.quantity / promo.discount_amount.to_i
          logger.info "ITEM QUANTITY #{oli.quantity}"
        else
          return
        end
    end
    
    self.order_line_items << oli
  end
  
  # CLASS METHODS =============================================================

  # Searches an order
  # Uses order number, first name, last name
  def self.search(search_term, count=false, limit_sql=nil)
    if (count == true) then
      sql = "SELECT COUNT(*) "
    else
      sql = "SELECT DISTINCT orders.* "
		end
		sql << "FROM orders "
		sql << "JOIN order_addresses ON orders.order_user_id = order_addresses.order_user_id "
		sql << "WHERE orders.order_number = ? "
		sql << "OR order_addresses.first_name LIKE ? "
		sql << "OR order_addresses.last_name LIKE ? "
		sql << "OR CONCAT(order_addresses.first_name, ' ', order_addresses.last_name) LIKE ? "
		sql << "ORDER BY orders.created_on DESC "
		sql << "LIMIT #{limit_sql}" if limit_sql
		arg_arr = [sql, search_term, "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"]
		if (count == true) then
		  count_by_sql(arg_arr)
	  else
		  find_by_sql(arg_arr)
	  end
  end
  
  # Finds orders by country
  #
  def self.find_by_country(country_id, count=false, limit_sql=nil)
    if (count == true) then
      sql = "SELECT COUNT(*) "
    else
      sql = "SELECT DISTINCT orders.* "
    end
    sql << "FROM orders "
    sql << "INNER JOIN order_users ON order_users.id = orders.order_user_id "
    sql << "INNER JOIN order_addresses ON ( "
    sql << "  order_addresses.country_id = ? AND order_addresses.order_user_id = order_users.id "
    sql << ")"
    arg_arr = [sql, country_id]
		if (count == true) then
		  count_by_sql(arg_arr)
	  else
		  find_by_sql(arg_arr)
	  end
  end

  # Generates a unique order number.
  # This number isn't ID because we want to mask that from the customers.
  def self.generate_order_number
    record = Object.new
    while record
      random = rand(999999999)
      record = find(:first, :conditions => ["order_number = ?", random])
    end
    return random
  end

  # Returns array of sales totals (hash) for a given year.
  # Hash contains
  #   * :number_of_sales
  #   * :sales_total
  #   * :tax
  #   * :shipping
  def self.get_totals_for_year(year)
    months = Array.new
    0.upto(12) { |i|
      sql = "SELECT COUNT(*) AS number_of_sales, SUM(product_cost) AS sales_total, "
      sql << "SUM(tax) AS tax, SUM(shipping_cost) AS shipping "
      sql << "FROM orders "
      sql << "WHERE YEAR(created_on) = ? "
      if i != 0 then
        sql << "AND MONTH(created_on) = ? "
      end
      sql << "AND (order_status_code_id = 5 OR order_status_code_id = 6 OR order_status_code_id = 7) "
      sql << "LIMIT 0,1"
      if i != 0 then
        months[i] = self.find_by_sql([sql, year, i])[0]
      else
        months[i] = self.find_by_sql([sql, year])[0]
      end
    }
    return months
  end

	# Gets a CSV string that represents an order list.
	def self.get_csv_for_orders(order_list)
    require 'fastercsv'
    csv_string = FasterCSV.generate do |csv|
      # Do header generation 1st
      csv << [
        "OrderNumber", "Company", "ShippingType", "Date", 
        "BillLastName", "BillFirstName", "BillAddress", "BillCity", 
        "BillState", "BillZip", "BillCountry", "BillTelephone", 
        "ShipLastName", "ShipFirstName", "ShipAddress", "ShipCity", 
        "ShipState", "ShipZip", "ShipCountry", "ShipTelephone",
        "Item1",
        "Quantity1", "Item2", "Quantity2", "Item3", "Quantity3", "Item4",
        "Quantity4", "Item5", "Quantity5", "Item6", "Quantity6", "Item7",
        "Quantity7", "Item8", "Quantity8", "Item9", "Quantity9", "Item10",
        "Quantity10", "Item11", "Quantity11", "Item12", "Quantity12", "Item13",
        "Quantity13", "Item14", "Quantity14", "Item15", "Quantity15", "Item16",
        "Quantity16"
      ]
      for order in order_list
        bill = order.billing_address
        ship = order.shipping_address
        pretty_date = order.created_on.strftime("%m/%d/%y")
        if !order.order_shipping_type.nil?
          ship_code = order.order_shipping_type.code
        else
          ship_code = ''
        end
        order_arr = [
          order.order_number, '', ship_code, pretty_date,
          bill.last_name, bill.first_name, bill.address, bill.city,
          bill.state, bill.zip, bill.country.name, bill.telephone,
          ship.last_name, ship.first_name, ship.address, ship.city,
          ship.state, ship.zip, ship.country.name, ship.telephone 
        ]
        item_arr = []
        # Generate spaces for items up to 16 deep
        0.upto(15) do |i|
          item = order.order_line_items[i]
          if !item.nil? && !item.product.nil?  then
            item_arr << item.product.code
            item_arr << item.quantity
          else
            item_arr << ''
            item_arr << ''
          end
        end
        # Add csv string by joining arrays
        csv << order_arr.concat(item_arr)
      end
    end
    return csv_string
  end

	# Returns an XML string for each order in the order list.
	# This format is for sending orders to Tony's Fine Foods
	def self.get_xml_for_orders(order_list)
		xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		xml << "<orders>\n"
		for order in order_list
		  if order.order_shipping_type
		    shipping_type = order.order_shipping_type.code
		  else
		    shipping_type = ''
	    end
		  pretty_date = order.created_on.strftime("%m/%d/%y")
		  xml << "	<order>\n"
  		xml << "		<date>#{pretty_date}</date>\n"
  		xml << "		<shippingCode>#{shipping_type}</shippingCode>\n"
  		xml << "		<invoiceNumber>#{order.order_number}</invoiceNumber>\n"
  		xml << "		<emailAddress>#{order.order_user.email_address}</emailAddress>\n"
      # Shipping address
      address = order.shipping_address
      xml << "		<shippingAddress>\n"
  		xml << "			<firstName>#{address.first_name}</firstName>\n"
  		xml << "			<lastName>#{address.last_name}</lastName>\n"
  		xml << "			<address1>#{address.address}</address1>\n"
  		xml << "			<address2></address2>\n"
  		xml << "			<city>#{address.city}</city>\n"
  		xml << "			<state>#{address.state}</state>\n"
  		xml << "			<zip>#{address.zip}</zip>\n"
  		xml << "			<countryCode>#{address.country.fedex_code}</countryCode>\n"
  		xml << "			<telephone>#{address.telephone}</telephone>\n"
  		xml << "		</shippingAddress>\n"
  		# Items
  		xml << "		<items>\n"
  		for item in order.order_line_items
  		  xml << "			<item>\n"
    		xml << "				<name>#{item.product.name}</name>\n"
    		xml << "				<id>#{item.product.code}</id>\n"
    		xml << "				<quantity>#{item.quantity}</quantity>\n"
    		xml << "			</item>\n"
		  end
  		xml << "		</items>\n"
  		# End
      xml << "	</order>\n"
    end
	  # End orders
	  xml << "</orders>\n"
	  return xml
	end

  # INSTANCE METHODS ==========================================================

  # Shortcut to find order_line_item for a promotion that has been applied.
  def promotion_line_item
    if self.promotion
      return self.order_line_items.find_by_name(self.promotion.description)
    else
      return nil
    end
  end

	# Order status name
  def status
    code = OrderStatusCode.find(:first, :conditions => ["id = ?", self.order_status_code_id])
    code.name
  end

  # Shortcut to items
  def items
    self.order_line_items
  end

	# Total for the order, including shipping and tax.
	#
  def total
    logger.info "CALCULATING SHIPPING TOTAL"
    logger.info "LINE ITEMS TOTAL: #{self.line_items_total}"
    logger.info "SHIPPING COST: #{self.shipping_cost}"
    logger.info "TAX COST: #{self.tax_cost}"
    self.line_items_total + self.shipping_cost + self.tax_cost
  end
  
  # The tax of items if applied.
  #
  def tax_cost
    (self.line_items_total) * (self.tax/100)
  end

  def name
    return "#{billing_address.first_name} #{billing_address.last_name}"
  end

  def account
    self.order_account
  end

	# Sets line items from the product output table on the edit page.
	#
	# Deletes any line items with a quantity of 0.
	# Adds line items with a quantity > 0.
	#
	# This is called from update in our controllers.
	# What's passed looks something like this...
	#   @products = {'1' => {'quantity' => 2}, '2' => {'quantity' => 0}, etc}
	def line_items=(products)
		# Clear out all line items
		self.order_line_items.clear
		# Go through all products
		products.each do |id, product|
		  quantity = product['quantity']
		  if quantity.blank? then
		    quantity = 0
      else
			  quantity = Integer(quantity)
		  end

			if (quantity > 0) then
				new_item = self.order_line_items.build
				logger.info("\n\nBUILDING NEW LINE ITEM\n")
				logger.info(new_item.inspect+"\n")
				new_item.quantity = quantity
				new_item.item_id = id
				new_item.unit_price = Item.find(:first, :conditions => "id = #{id}").price
				new_item.save
			end
		end
	end

	# Do we have a valid transaction id
	def contains_valid_transaction_id?()
		return (!self.auth_transaction_id.blank? && self.auth_transaction_id != 0)
	end

	# Determines if an order has a line item based on product id
	def has_line_item?(id)
		self.order_line_items.each do |item|
			return true if item.id == id
		end
		return false
	end

	# Gets quantity of a product if exists in current line items.
	def get_line_item_quantity(id)
		self.order_line_items.each do |item|
			return item.quantity if item.id == id
		end
		return 0
	end

	# Gets a subtotal for line items based on product id
	def get_line_item_total(id)
		self.order_line_items.each do |item|
			return item.total if item.id == id
		end
		return 0
	end

	# Grabs the total amount of all line items associated with this order
	def line_items_total
		total = 0
		for item in self.order_line_items
			total += item.total
		end
		return total
	end

	# Adds a new order note from the edit page.
	#
	# We display notes as read-only, so we only have to use a text field
	# instead of multiple records.
	def new_notes=(note)
		if !note.blank? then
			time = Time.now.strftime("%m-%d-%y %I:%M %p")
			new_note = "<p>#{note}<br/>"
			new_note << "<span class=\"info\">"
			new_note << "[#{time}]"
			new_note << "</span></p>"
			if self.notes.blank? then
				self.notes = new_note
			else
				self.notes << new_note
			end
		end
	end

	# Calculates the weight of an order
	def weight
		weight = 0
		self.order_line_items.each do |item|
			weight += item.quantity * item.product.weight rescue 0
		end
		return weight
	end

  # Gets a flat shipping price for an order.
  # This is if we're not using live rate calculation usually
  #
  # A lot of people will want this overridden in their app
  def get_flat_shipping_price
    return Preference.find_by_name('store_handling_fee').value.to_f
  end

  # Gets all LIVE shipping prices for an order.
  #
  # Returns an array of OrderShippingTypes
  def get_shipping_prices
    prices = []
    # If they're in the USA
    address = self.shipping_address
    
    # TODO - set this country_id as a preference in the admin UI
    #
    if address.country_id == 1 then
      shipping_types = OrderShippingType.get_domestic
    else 
      shipping_types = OrderShippingType.get_foreign
    end

    for type in shipping_types
      type.calculate_price(self.weight)
      prices << type
    end

    return prices

  end

  # Runs an order transaction.
  # Farms out the work to an Authorize.net or PayPal method
  # (or one of your devising).
  #
  # Should return TRUE if the process is successful.
  # Should return AN ERROR MESSAGE if not...
  #
  def run_transaction
    cc_processor = Order.get_cc_processor 
    if cc_processor == Preference::CC_PROCESSORS[0]
      run_transaction_authorize
    elsif cc_processor == Preference::CC_PROCESSORS[1]
      run_transaction_paypal_ipn
    else
      throw "The currently set preference for cc_processor is not recognized. You might want to add it to the code..."
    end
  end
 
  # Check to see which cc processor is used
  def self.get_cc_processor
    Preference.find_by_name('cc_processor').value
  end

  # Get the login info for the cc processor (if any)
  def self.get_cc_login
    Preference.find_by_name('cc_login').value
  end

  # Runs an order through Authorize.net
  #
  # Returns true 
  #
  def run_transaction_authorize
    ba = self.billing_address
  
    # For debugging with a test account...
    # ActiveMerchant::Billing::Base.mode = :test
    
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :number     => self.account.cc_number,
      :month      => self.account.expiration_month,
      :year       => self.account.expiration_year,
      :first_name => ba.first_name,
      :last_name  => ba.last_name
    )
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(
      :login      => Preference.find_by_name('cc_login').value,
      :password   => Preference.find_by_name('cc_pass').value,
      :ssl_strict => true,
      :test       => Preference.find_by_name('store_test_transactions').is_true?
    )
    address = {
      :address1 => ba.address,
      :city     => ba.city,
      :state    => ba.state,
      :zip      => ba.zip,
      :country  => ba.country.name
    }
    
    # AM requires it's purchaes in CENTS, so adjust accordingly.
    response = gateway.purchase(self.total.to_f*100, credit_card, {:address => address})
  	# Save transaction id for later
  	self.auth_transaction_id = response.params[:transaction_id]
  			
		# Handle the response
		if response.success?
			logger.info("\n\nORDER TRANSACTION ID - #{self.auth_transaction_id}\n\n")
      # Set completed
      self.cleanup_successful
      # Send success message
      begin
        self.deliver_receipt
      rescue => e
        logger.error("FAILED TO SEND THE CONFIRM EMAIL: #{e}")
      end
      return true
	  else
	    # Log errors
      logger.error("\n\n[ERROR] FAILED ORDER \n")
      logger.error(response.inspect)
      logger.error(response.message)
      logger.error("\n\n")
	    # Order failed - store transaction id
      self.cleanup_failed(response.message)
      # Send failed message
      begin
        self.deliver_failed
      rescue => e
        logger.error("FAILED TO SEND THE CONFIRM EMAIL: #{e}")
      end

	    return response.message
    end
    
		return false
  end
  
  # Do the cleanup for orders run through Paypal
  #
  def run_transaction_paypal_ipn

    status_code = self.order_status_code_id

    # Under normal conditions, the paypal ipn should be confirmed already
    # but we can't count on that.  Assign a status of 4 (awaiting payment)
    # if the status is still 1 (cart)
    if status_code == 1
      self.order_status_code_id = 4 
      self.new_notes = "The order was processed at PayPal but not yet confirmed."
    end

    self.save

    self.order_status_code_id
 
  end

	# Cleans up a successful order
	def cleanup_successful
	  # Decrement inventory for items...
	  # Also driven by the inventory control preference from the
	  # admin UI
	  if Preference.find_by_name('store_use_inventory_control').is_true?
  	  for oli in self.order_line_items do
  	    oli.item.update_attribute('quantity', oli.item.quantity-oli.quantity)if oli.quantity rescue false && oli.item.quantity rescue false
      end
    end
	  
		self.order_status_code_id = 5
    self.new_notes="Order completed."
    if Preference.find_by_name('cc_clear_after_order').is_true?
      self.account.clear_personal_information
    end
    self.save
	end

	# Cleans up a failed order
	def cleanup_failed(msg)
		self.order_status_code_id = 3
    self.new_notes="Order failed!<br/>#{msg}"
    self.save
	end


  # We define deliver_receipt here because ActionMailer can't seem to render
  # components inside a template.
  #
  # I'm getting around this by passing the text into the mailer.
  def deliver_receipt
    @content_node = ContentNode.find(:first, :conditions => ["name = ?", 'OrderReceipt'])
    if @content_node
      OrdersMailer.deliver_receipt(self, @content_node.content)
    else
      logger.error("The system didn't found a content node record named \"OrderReceipt\", this record " +
      "is used in the e-mail body. The e-mail deliver cannot proceed.")
    end
  end

  # If we're going to define deliver_receipt here, why not wrap deliver_failed as well?
  def deliver_failed
    OrdersMailer.deliver_failed(self)
  end

  # Is a discount present?
  def is_discounted?
    self.order_line_items.collect.each {|item| return true if item.unit_price < 0 }
    false
  end


#================== paypal IPN verification and execution ======================

  def self.matches_ipn(notification, order, details)
    # Compare the information in the notification with the order.  The
    # Paypal::Notification object doesn't provide everything we want to verify
    # so we need to dig into the params[] array too.

    passed = true  #gives an inital clean slate

    # On occasion, an order will not be rounded to 2 decimal places
    if (order.total.to_f*100).round/100.00 != notification.gross.to_f
      passed = false 

      logger.error(">>>The total passed back from PayPal doesn't match the
                    total for invoice number #{notification.invoice}.
		    Order total is #{((order.total.to_f*100).round/100.00).to_s} 
		    and PayPal returned
		    #{notification.gross.to_s}")
    end

    if details[:business] != Preference.find_by_name('cc_login').value
      passed = false
      logger.error(">>>The business address passed back from PayPal is not 
                    correct.  This likely means someone else ate your lunch.")
    end

    if Order.find_by_auth_transaction_id(details[:txn_id])
      passed = false
      logger.error(">>>The authorization ID passed back from PayPal already
                    exists in our database.  This would indicate that the
		    user has used information from a previous transaction
		    to spoof a new one.")
    end

    logger.error(">>>PAYPAL FRAUD DETECTED! Please investigate<<<") if !passed

    # PayPal also allows purchasers to add special instructions to sellers. We
    # should capture this and add it to the order notes

    if details[:memo] && details[:memo].length > 0
      order.new_notes = "CUSTOMER REMARKS: "+details[:memo]
    end

    if details[:address_street] && 
       details[:address_street] != order.shipping_address.address
      order.new_notes ="The shipping address supplied by PayPal doesn't match
                        the shipping address for this order. PayPal
			sent the following address:<br/>
			#{details[:address_street]}<br/>
			#{details[:address_city]}, #{details[:address_state]}<br/>
			#{details[:address_zip]}<br/>
			<b>Please contact the customer for clarification.<b>"
    end

    passed

  end

  def self.pass_ipn(order, auth_id)
    order.order_status_code_id = 5
    order.new_notes = "Order paid through PayPal.  Ready to ship."
    order.auth_transaction_id = auth_id
    # Set completed
    order.cleanup_successful
    # Send success message
    begin
      order.deliver_receipt
    rescue => e
      logger.error("FAILED TO SEND THE CONFIRM EMAIL: #{e}")
    end
    order.save
  end

  def self.fail_ipn(order)
    #TODO - create a custom id for fraud.
    message = "FRAUD ALERT -- please investigate."
    order.order_status_code_id = 3
    order.new_notes = message
    order.cleanup_failed(message)
    # Send failed message
    begin
      order.deliver_failed 
    rescue => e
      logger.error("FAILED TO SEND THE CONFIRM EMAIL: #{e}")
    end
    order.save
  end
end
