# == Schema Information
#
# Table name: publications
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  logo                 :string(255)
#  organization_id      :integer
#  website              :string(255)
#  publishing_frequency :string(255)
#  notes                :text
#  parent_id            :integer
#  category_override    :string(255)
#  tagline              :text
#  links                :text
#  social_media         :text
#  general              :text
#  header               :text
#  pub_type             :string(255)
#  display_attributes   :boolean          default(FALSE)
#

require 'spec_helper'

describe Publication do
  before do
    @publication = FactoryGirl.create(:publication)
  end

  describe "latest_presentation" do
    it "should return nil if there are no presentation contents" do
      @publication.latest_presentation.should == nil
    end

    it "should return the most recent presentation content" do
      c1 = FactoryGirl.create(:content, pubdate: 1.day.ago, source: @publication, category: "presentation")
      c2 = FactoryGirl.create(:content, pubdate: 2.days.ago, source: @publication, category: "presentation")
      @publication.latest_presentation.should == c1
    end
  end

end
