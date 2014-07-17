# == Schema Information
#
# Table name: promotions
#
#  id             :integer          not null, primary key
#  active         :boolean
#  banner         :string(255)
#  publication_id :integer
#  content_id     :integer
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe Promotion do
  before do
    ImageUploader.storage = :file
    @pub = FactoryGirl.create(:publication)
    @content = FactoryGirl.create(:content)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  let(:valid_params) do
    { banner: File.open("spec/fixtures/photo.jpg", "r"),
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

  context "without a publication" do
    let (:params) { valid_params }
    subject { Promotion.create params }

    it "should not be valid" do
      expect(subject).to_not be_valid
    end

    it "should not create a new promotion" do
      expect{subject}.to_not change{Promotion.count}
    end
  end

  context "without an upload" do
    let (:params) do 
      valid_params.delete(:banner)
      valid_params
    end

    it "should not be valid" do
      expect(subject).to_not be_valid
    end

    it "should not create a new promotion" do
      expect{subject}.to_not change{Promotion.count}
    end
  end
end
