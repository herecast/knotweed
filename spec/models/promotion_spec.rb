# == Schema Information
#
# Table name: promotions
#
#  id             :integer          not null, primary key
#  active         :boolean
#  publication_id :integer
#  content_id     :integer
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  target_url     :string(255)
#

require 'spec_helper'

describe Promotion do
  before do
    ImageUploader.storage = :file
    @pub = FactoryGirl.create(:publication)
    @content = FactoryGirl.create(:content)
    Promotion.any_instance.stub(:update_active_promotions).and_return(true)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  let(:valid_params) do
    { 
      description: "What a terrible promotion"
    }
  end

  subject do 
    p = Promotion.create params 
    p.publication = @pub
    p.content = @content
    p.save
    p
  end

  context "with valid params" do
    let (:params) { valid_params }
    it "should be valid" do
      expect(subject).to be_valid
    end

    it "should create a new promotion" do
      expect{subject}.to change{Promotion.count}.by(1)
    end
  end

end
