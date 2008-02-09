# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	include Substruct
	
	def current_user_notice
    unless session[:user]
      link_to "Log In", :controller => "/accounts", :action=>"login"
    else
      link_to "Log Out", :controller => "/accounts", :action=>"logout"
    end
  end
  
  def make_label(name, required=false)
    output_str = "<label>"
    output_str << "<span style=\"color:red;\">*</span>" if required == true
    output_str << name
    output_str << "</label>"
    return output_str
  end
  
  # Overridden number_to_currency which can handle
  # an array for price "ranges", as passed back by
  # Product::display_price
  #
  # We only pass 2 items in, but could display more...
  #
  def sub_number_to_currency(number, options = {})
    if number.class == Array
      str = number_to_currency(number[0], options) + "+"
    else
      str = number_to_currency(number, options)
    end
    
    return str
  end

  def make_product(image_path, link, title, cost=nil, on_sale=false, is_new=false)
    product = '<div class="product">'
    # Add 'on sale' image if applicable
    if on_sale
      product << '<img src="/images/ui/icons/on-sale.gif" alt="On Sale" border="0" class="icon" />'
    end
    if is_new && !on_sale
      product << '<img src="/images/ui/icons/new.gif" alt="New" border="0" class="icon" />'
    end
    product << %Q/
    		<div class="product_top"><\/div>
    		<div class="product_main">
    			<div class="product_image"> 
    			  <a href="#{link}">#{image_tag(image_path, :alt => title)}<\/a><br\/>
    			<\/div>
    			<div class="product_title">
    			  <a href="#{link}\">#{title}<\/a><br\/>
    			<\/div>
    /
    if cost
      product << %Q/ <span class="money">US #{sub_number_to_currency(cost)}<\/span> /
    end
    product << %Q/
    		<\/div>
    		<div class="product_bottom"><\/div>
    /
    return product << '</div>'
  end
  
  # When browsing the store by tags we need to know what
  # is the main "parent" tag or tag group.
  #
  # This lets us display the "active" state in the UI
  #
  def is_main_tab_active?(tab_id)
    if @viewing_tags && @viewing_tags[0].id == tab_id
      @show_subnav = true
      @main_tag_active = Tag.find(tab_id)
      @subnav_tags = @main_tag_active.children
      return true
    end
    
    return false
  end
  
  def is_sub_tab_active?(tab_id)
    if @viewing_tags && @viewing_tags.size > 1 && @viewing_tags[1].id == tab_id
      @show_subnav = true
      return true
    end

    return false
  end
  
end
