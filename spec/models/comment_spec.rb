# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Comment, :type => :model do
  before do
    @content = FactoryGirl.create :content, pubdate: 1.day.ago
    @comment = FactoryGirl.create :comment, content: @content
  end

  describe "method missing override" do
    it "should allow access to content attributes directly" do
      expect(@comment.title).to eq(@content.title)
      expect(@comment.authors).to eq(@content.authors)
      expect(@comment.pubdate).to eq(@content.pubdate)
    end

    it "should retain normal method_missing behavior if not a content attribute" do
      expect { @comment.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe "after_save" do
    it "should also save the associated content record" do
      @content.title = "Changed Title"
      @comment.save # should trigger @content.save callback
      expect(@content.reload.title).to eq "Changed Title"
    end
  end

  describe "after_create" do
    before do
      @parent = FactoryGirl.create :content, pubdate: 1.week.ago
      @user = FactoryGirl.create :admin
    end

    it "should increase the counter comments" do
      @content.parent = @parent
      @content.save
      count = @parent.comment_count
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.comment_count).to eq(count + 1)
    end

    it "should increase the counter commenters" do
      User.current = @user
      count = @parent.commenter_count
      @content = FactoryGirl.create :content
      @content.parent = @parent
      @content.save
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.commenter_count).to eq(count + 1)
    end

    it "should not increase the counter commenters" do
      User.current=@user
      count = @parent.commenter_count
      @content = FactoryGirl.create :content
      @content.parent = @parent
      @content.save
      @content = FactoryGirl.create :content
      @content.parent = @parent
      @content.save
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.commenter_count).to eq(count)
    end
  end
end
