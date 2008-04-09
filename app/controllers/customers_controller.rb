# Deals with customer logins, previous orders and wishlists.
#
class CustomersController < ApplicationController
  layout 'main'
  before_filter :ssl_required

	# Check permissions for everything on within side.
  before_filter :login_required,
	  :except => [:login, :check_email_address, :reset_password, :new]

  # Logs the customer in using email address &
  # order number OR password
  def login
    @title = "Customer Login"
    @is_modal = (params[:modal] == 'true')
    
    if request.post?
      if customer = OrderUser.authenticate(params[:login], params[:password])
        log_customer_in(customer)
				flash[:notice]  = "Login successful"
				# If we're modal return a page that just refreshes things.
				if @is_modal
				  render :template => '/shared/modal_refresh', :layout => 'modal' and return
        else
          redirect_back_or_default :action => 'orders'
        end
      else
        flash.now[:notice]  = "Login unsuccessful"
      end
    end
    # Can be called from the store page.
    # Prompts existing users to login.
    if @is_modal
      render :layout => 'modal'
    end
  end
  
  def logout
    session[:customer] = nil
    flash[:notice] = "You've been logged out."
    redirect_to '/' and return
  end
  
  # Creates a new customer
  #
  def new
    @title = "New Account"
    # Update account details
    @customer = OrderUser.new
    if request.post?
      @customer.attributes = params[:customer]
      if @customer.save
        flash[:notice] = "Your account has been created."
        log_customer_in(@customer)
        # If we've set a return_to url, go there.
        if session[:return_to]
          redirect_to session[:return_to]
        else
          redirect_to :action => 'wishlist' and return
        end
      else
        flash.now[:notice] = "There was a problem creating your account."
        render and return
      end
    end    
  end
  
  
  # Account details
  # Can change email or password from this.
  def account
    @title = "Your Account Details"
    # Update account details
    if request.post?
      if @customer.update_attributes(params[:customer])
        flash.now[:notice] = "Account details saved."
      else
        flash.now[:notice] = "There was a problem saving your account."
      end
    end
  end
  
  # Resets password for customer, emails it to them.
  #
  def reset_password
    @title = "Reset Password"
    @is_modal = (params[:modal] == 'true')
    
    if request.post?
      if customer = OrderUser.find_by_email_address(params[:login])
        customer.reset_password()
        flash[:notice] = "Your password has been reset and emailed to you."
        redirect_to :action => 'login',
          :params => {
            :login => params[:login],
            :modal => params[:modal]
          }
        return
      else
        flash.now[:notice] = "That account wasn't found in our system."
        return
      end
    end
    
    # Can be called from the store page.
    # Prompts existing users to login.
    if @is_modal
      render :layout => 'modal'
    end
  end

  # Displays all orders for a customer
  def orders
    @title = "Your Orders"
    @orders = @customer.orders.paginate(
      :page => params[:page],
      :per_page => 10
    )
  end

  # Wishlist items
  def wishlist
    @title = "Your Wishlist"
    @items = @customer.items.paginate(
      :page => params[:page],
      :per_page => 20
    )
  end
  
  # Adds an item to the wishlist.
  # Redirects to the wishlist...
  def add_to_wishlist
    if params[:id]
      if item = Item.find_by_id(params[:id])
        @customer.add_item_to_wishlist(item)
      else
        flash[:notice] = "Sorry, we couldn't find the item that you wanted to add to your wishlist. Please try again."        
      end
    else
      flash[:notice] = "You didn't specify an item to add to your wishlist..."
    end
    redirect_to :action => 'wishlist' and return
  end
  
  # AJAX METHOD
  #
  # Removes item from wishlist.
  #
  def remove_wishlist_item
    if item = Item.find_by_id(params[:id])
      @customer.remove_item_from_wishlist(item)
    end
    render :text => ''
  end
  
	
	# Checks email address via AJAX to see if exists already
	#
	# Shows/hides form via RJS if necessary to prompt a login
	# by the user.
	#
	def check_email_address
	  logger.info "Checking email address"
	  logger.info params.inspect
	  user = OrderUser.find_by_email_address(params[:email_address])
	  if user
	    # Show pop window with login page...
	    render(:update) { |page| page.call('showLoginWin', user.email_address) }
	    return
    else
      render(:update) { |page| page.call('hidePopWin') }
      return
    end
  end
	
	# PRIVATE METHODS ===========================================================
	private

    def log_customer_in(customer)
      session[:customer] = customer.id
    end
	
    # Makes sure customer is logged in before accessing stuff here.
    #
    def login_required
      if session[:customer]
        return true
      end

      # store current location so that we can 
      # come back after the user logged in
      store_location
  
      redirect_to :action =>"login" and return false 
    end
	
    # store current uri in  the session.
    # we can return to this location by calling return_location
    def store_location
      session[:return_to] = request.request_uri
    end
	
	  # Move to the last store_location call or to the passed default one
    def redirect_back_or_default(default)
      if session[:return_to].nil?
        redirect_to default
      else
        redirect_to session[:return_to]
        session[:return_to] = nil
      end
    end
	
end
