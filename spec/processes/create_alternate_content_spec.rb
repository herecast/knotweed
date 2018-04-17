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

    context "when alternate defaults have been overridden" do
      let(:alt_title) { 'Alt title' }
      let(:alt_organization_id) { 41 }
      let(:alt_authors) { 'Alt authors' }
      let(:alt_text) { 'Alt text' }
      let(:alt_image_url) { 'Alt-image-url' }

      before do
        @content.update_attributes(
          alternate_title: alt_title,
          alternate_organization_id: alt_organization_id,
          alternate_authors: alt_authors,
          alternate_text: alt_text,
          alternate_image_url: alt_image_url
        )
      end

      it "returns the override values" do
        alternate_content = subject
        expect(alternate_content.title).to eq alt_title
        expect(alternate_content.organization_id).to eq alt_organization_id
        expect(alternate_content.authors).to eq alt_authors
        expect(alternate_content.raw_content).to eq alt_text
        expect(alternate_content.images[0].image_url).to eq alt_image_url
      end
    end
  end
end