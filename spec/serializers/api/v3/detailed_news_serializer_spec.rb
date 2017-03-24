require 'spec_helper'

describe Api::V3::DetailedNewsSerializer do
  let (:serialized_object) { JSON.parse(Api::V3::DetailedNewsSerializer.new(@content, root: false).to_json) }

  before do
    @content = FactoryGirl.create :content, raw_content: "<div><img src=\"http://knotweed.s3.amazonaws.com/asdf/wer.png\" /></div>"
  end

  around(:each) do |example|
    old_uri                    = ENV["OPTIMIZED_IMAGE_URI"]
    ENV["OPTIMIZED_IMAGE_URI"] = "http://thumbor.subtext.org"

    example.run

    ENV["OPTIMIZED_IMAGE_URI"] = old_uri
  end

  context 'content' do
    it 'has an optimized image URL' do
      expect(serialized_object["split_content"].to_s).to include "#{ENV['OPTIMIZED_IMAGE_URI']}/unsafe/fit-in/600x1800"
    end
  end
end
