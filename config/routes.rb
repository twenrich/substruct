ActionController::Routing::Routes.draw do |map|
  # default
  map.connect '',
    :controller => 'content_nodes',
    :action     => 'show_by_name',
    :name       => 'home'
  map.connect '/',
    :controller => 'content_nodes',
    :action     => 'show_by_name',
    :name       => 'home'

  # Default administration mapping
  map.connect 'admin',
    :controller => 'admin/orders',
    :action     => 'index'

  map.connect '/blog',
    :controller => 'content_nodes',
    :action     => 'index'

  map.connect '/blog/section/:section_name',
    :controller => 'content_nodes',
    :action     => 'list_by_section'

  # Static route blog content through our content_node controller
  map.connect '/blog/:name',
    :controller => 'content_nodes',
    :action     => 'show_by_name'


  map.connect '/contact',
    :controller => 'questions',
    :action     => 'ask'

  map.connect '/store/show_by_tags/*tags',
    :controller => 'store',
    :action     => 'show_by_tags'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'

  # For things like /about_us, etc
  map.connect ':name',
    :controller => 'content_nodes',
    :action     => 'show_by_name'
end
