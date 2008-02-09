# This is the base model for Product and ProductVariation.
#
#
class Item < ActiveRecord::Base
  has_many :order_line_items
  has_many :wishlist_items, :dependent => :destroy
  validates_presence_of :name, :code
  validates_uniqueness_of :code
  
  #############################################################################
  # CALLBACKS
  #############################################################################
  
  
  #############################################################################
  # CLASS METHODS
  #############################################################################
  
  # Name output for product suggestion JS
  # 
  def suggestion_name
    "#{self.code}: #{self.name}"
  end
  
end
