require File.dirname(__FILE__) + '/../test_helper'

class ContentNodeTest < Test::Unit::TestCase
  fixtures :content_nodes, :content_node_types

	def setup
	end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ContentNode, content_nodes(:about_us)
  end

	def test_url
		assert_not_nil content_nodes(:about_us).url
	end
	
	def test_is_blog_post
		assert_equal content_nodes(:about_us).is_blog_post?, false
		assert_equal content_nodes(:blog_post).is_blog_post?, true
	end

end
