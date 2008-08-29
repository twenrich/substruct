# ActionController::Routing::Routes.draw do |map|
  # default
  connect '',
    :controller => 'content_nodes',
    :action     => 'show_by_name',
    :name       => 'home'
  connect '/',
    :controller => 'content_nodes',
    :action     => 'show_by_name',
    :name       => 'home'

  # Default administration mapping
  connect 'admin',
    :controller => 'admin/orders',
    :action     => 'index'

  connect '/blog',
    :controller => 'content_nodes',
    :action     => 'index'

  connect '/blog/section/:section_name',
    :controller => 'content_nodes',
    :action     => 'list_by_section'

  # Static route blog content through our content_node controller
  connect '/blog/:name',
    :controller => 'content_nodes',
    :action     => 'show_by_name'


  connect '/contact',
    :controller => 'questions',
    :action     => 'ask'

  connect '/store/show_by_tags/*tags',
    :controller => 'store',
    :action     => 'show_by_tags'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  connect ':controller/:action/:id.:format'
  connect ':controller/:action/:id'

  # For things like /about_us, etc
  connect ':name',
    :controller => 'content_nodes',
    :action     => 'show_by_name'
# end
