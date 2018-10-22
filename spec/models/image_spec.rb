# == Schema Information
#
# Table name: images
#
#  id             :bigint(8)        not null, primary key
#  caption        :string(255)
#  credit         :string(255)
#  image          :string(255)
#  imageable_type :string(255)
#  imageable_id   :bigint(8)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_url     :string(400)
#  primary        :boolean          default(FALSE)
#  width          :integer
#  height         :integer
#  file_extension :string
#  position       :integer          default(0)
#
# Indexes
#
#  idx_16634_index_images_on_imageable_type_and_imageable_id  (imageable_type,imageable_id)
#

require 'spec_helper'

describe Image, :type => :model do

  describe 'validation' do
    describe '#image_minimum_size' do
      context "when image is too small" do
        before do
          @image = FactoryGirl.build :image, image: File.open(File.join(Rails.root, '/spec/fixtures/small.jpg'))
        end

        it "returns validation error" do
          expect(@image).to be_invalid
        end
      end

      context 'when image is large enough' do
        before do
          @image = FactoryGirl.build :image, image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
        end

        it "returns no error" do
          expect(@image).to be_valid
        end
      end
      
      context 'when image does not exist in server filesystem' do
        before do
          @image = FactoryGirl.create :image, image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
        end
        
        it 'does not try to validate image' do
          File.delete(@image.image.current_path)
          expect(@image).to be_valid
        end
      end
    end
  end

  describe 'ensure_only_one_primary' do
    before do
      @imgble = FactoryGirl.create :content
      @img1 = FactoryGirl.create :image, imageable: @imgble
    end

    it 'should not set primary to true if the image is the only one on the content' do
      expect(@img1.primary).to be false
    end

    it 'should update all other images on the imageable object to primary=false when creating a new primary image' do
      img2 = FactoryGirl.create :image, primary: true, imageable: @imgble
      expect(@img1.reload.primary).to be_falsey
    end
  end

  describe '.in_rendering_order' do
    before do
      @imgble = FactoryGirl.create :content
      @img1 = FactoryGirl.create :image, imageable: @imgble, position: 99
      @img2 = FactoryGirl.create :image, primary: true, imageable: @imgble, position: 50
      @img3 = FactoryGirl.create :image, imageable: @imgble, position: 1
    end

    it 'renders the images in order of primary first, then the remaining images by position' do
      expect(@imgble.images.order(:id        ).to_a).to eq [@img2, @img1, @img3]
      expect(@imgble.images.in_rendering_order.to_a).to eq [@img2, @img3, @img1]
    end
  end

end
