# == Schema Information
#
# Table name: category_corrections
#
#  id           :integer          not null, primary key
#  content_id   :integer
#  old_category :string(255)
#  new_category :string(255)
#  user_email   :string(255)
#  title        :string(255)
#  content_body :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe CategoryCorrection do
  describe "after_create" do
    it "should update the category of the corresponding content and save the contents body" do
      c = FactoryGirl.create(:content)
      cat_cor = FactoryGirl.create(:category_correction, content: c)
      c = Content.find c.id
      c.category.should == cat_cor.new_category
      c.category_reviewed.should == true
      cat_cor.content_body.should == c.content
      cat_cor.title.should == c.title
    end

    it "should remove all previous category corrections attached to content" do
      c = FactoryGirl.create(:content)
      cat_cor_1 = FactoryGirl.create(:category_correction, content: c)
      cat_cor_2 = FactoryGirl.create(:category_correction, content: c)
      CategoryCorrection.where(content_id: c.id).count.should == 1
      CategoryCorrection.where(content_id: c.id)[0].should == cat_cor_2
    end

  end

  describe '#publish_corrections_to_dsp' do
    before do
      @content = FactoryGirl.create :content
      @category_correction = FactoryGirl.create :category_correction, content_id: @content.id
      @category_correction.content.repositories << FactoryGirl.create(:repository)
      stub_request(:any, "http://KW05055:knotweed05055@23.92.16.168:8081/openrdf-sesame/repositories/subtext/extract")
    end

    it "publishes to dsp" do
      response = @category_correction.publish_corrections_to_dsp
      expect(response.length).to eq 1
    end
  end

end
