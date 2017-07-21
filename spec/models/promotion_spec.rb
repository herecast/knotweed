# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  banner          :string(255)
#  organization_id :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#  created_by      :integer
#  updated_by      :integer
#  share_platform  :string
#

require 'spec_helper'

describe Promotion, :type => :model do
  before do
    @org = FactoryGirl.create(:organization)
    @content = FactoryGirl.create(:content)
    allow_any_instance_of(Promotion).to receive(:update_active_promotions).and_return(true)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  include_examples 'Auditable', Promotion

  let(:valid_params) do
    {
      description: "What a terrible promotion"
    }
  end

  subject do
    p = Promotion.create params
    p.organization = @org
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
