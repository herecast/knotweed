# == Schema Information
#
# Table name: images
#
#  id             :integer          not null, primary key
#  caption        :string(255)
#  credit         :string(255)
#  image          :string(255)
#  imageable_type :string(255)
#  imageable_id   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source_url     :string(400)
#  primary        :boolean          default(FALSE)
#

require 'spec_helper'

describe Image, :type => :model do

  describe 'ensure_only_one_primary' do
    before do
      @imgble = FactoryGirl.create :content
      @img1 = FactoryGirl.create :image, imageable: @imgble
    end

    it 'should set primary to true if the image is the only one on the content' do
      expect(@img1.primary).to be_truthy
    end

    it 'should update all other images on the imageable object to primary=false when creating a new primary image' do
      img2 = FactoryGirl.create :image, primary: true, imageable: @imgble
      expect(@img1.reload.primary).to be_falsey
    end
  end

end
