require 'spec_helper'

describe Api::V3::ImagesController do
  before do
    @market_post = FactoryGirl.create :market_post
    @file1 = fixture_file_upload('/photo.jpg', 'image/jpg')
  end

  describe 'POST create' do
    subject { post :create, image: { image: @file1, primary: false,
              content_id: @market_post.content.id }}

    it 'should create an image' do
      expect{subject}.to change{Image.count}.by 1
    end

    it 'should add an image to the content in question' do
      expect{subject}.to change{@market_post.content.images.count}.by 1
    end
  end

  describe 'PUT update' do
    before do
      @img = FactoryGirl.create :image, primary: false
      # need to have multiple images on the imageable or the first one is set to primary automatically
      @img2 = FactoryGirl.create :image, primary: true
      @market_post.content.images += [@img, @img2]
    end

    subject { put :update, id: @img.id, image: { primary: true } }

    it 'should update the primary attribute' do
      expect{subject}.to change{@img.reload.primary}.to true
    end
  end

  describe 'DELETE destroy' do
    before do
      @img = FactoryGirl.create :image
      @market_post.content.images << @img
    end

    subject { delete :destroy, id: @img.id }

    it 'should remove the image from the associated content' do
      expect{subject}.to change{@market_post.content.images.count}.by -1
    end

    it 'should destroy the image record' do
      expect{subject}.to change{Image.find_by_id(@img.id)}.from(@img).to(nil)
    end
  end
end
