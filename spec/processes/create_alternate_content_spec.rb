require 'rails_helper'

RSpec.describe CreateAlternateContent do

  describe "::call" do
    before do
      @old_title = 'Legacy Tatooine'
      @old_raw_content = 'So offensive!'
      @old_authors = 'Mean Dugs'
      @content = FactoryGirl.create :content, :news,
        title: @old_title,
        raw_content: @old_raw_content,
        authors: @old_authors,
        removed: true
    end

    subject { CreateAlternateContent.call(@content) }

    it "returns an unpersisted Content record with crisis attributes" do
      alternate_content = subject
      expect(alternate_content.class).to eq Content
      expect(alternate_content.persisted?).to be false
      expect(alternate_content.title).not_to eq @old_title
      expect(alternate_content.raw_content).not_to eq @old_raw_content
      expect(alternate_content.authors).not_to eq @old_authors
      expect(alternate_content.id).to eq @content.id
      expect(alternate_content.images[0].image_url).to eq 'https://s3.amazonaws.com/knotweed/duv/Default_Photo_News-01-1.jpg'
    end
  end
end