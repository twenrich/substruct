require File.dirname(__FILE__) + '/../test_helper'

class ImageTest < ActiveSupport::TestCase
  fixtures :items


  # Test if a valid image can be created with success.
  def test_should_create_image
    lightsabers_image = fixture_file_upload("/files/lightsabers.jpg", 'image/jpeg')

    an_image = Image.new
    an_image.uploaded_data = lightsabers_image
    assert an_image.save
    
    # We must erase the record and its files by hand, just calling destroy.
    assert an_image.destroy
  end


  # Test if an image can be associated with products.
  def test_should_associate_images
    a_product = items(:lightsaber)
    assert_equal a_product.images.count, 3

    lightsabers_image = fixture_file_upload("/files/lightsabers.jpg", 'image/jpeg')

    an_image = Image.new
    an_image.uploaded_data = lightsabers_image
    assert an_image.save
    
    a_product.images << an_image
    assert_equal a_product.images.count, 4
    
    # We must erase the record and its files by hand, just calling destroy.
    assert an_image.destroy
  end


  # Test if an image will generate and get rid of its files properly.
  def test_should_handle_files
    lightsabers_image = fixture_file_upload("/files/lightsabers.jpg", 'image/jpeg')

    an_image = Image.new
    an_image.uploaded_data = lightsabers_image
    assert an_image.save
    
    # Assert that the files exists.
    assert File.exist?(an_image.full_filename)
    for thumb in an_image.thumbnails
      assert File.exist?(thumb.full_filename)
    end
    
    # We must erase the record and its files by hand, just calling destroy.
    assert an_image.destroy
    # See if the files really was erased.
    for thumb in an_image.thumbnails
      assert !File.exist?(thumb.full_filename)
    end
    assert !File.exist?(an_image.full_filename)
  end


end
