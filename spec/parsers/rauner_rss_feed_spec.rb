require 'spec_helper'

# NOTE: this parser is designed for a specific RSS feed available at
#   raunerlibrary.blogspot.com/feeds/posts/default
# I'm deliberately not loading that into a fixture file here so that this
# spec will alert us if that changes, since that will break the parser.
describe 'Rauner Library RSS Feed Parser' do
  before(:all) { load File.join(Rails.root, 'lib', 'parsers', 'rauner_rss_feed.rb') }
  before(:each) { WebMock.allow_net_connect! }
  after { WebMock.disable_net_connect!(allow_localhost: true) }
  let(:url) { 'http://raunerlibrary.blogspot.com/feeds/posts/default' }
  let(:feed) { Nokogiri::XML(open(url)) }

  subject { parse_file(url, {}) }

  it 'should return an array containing content hashes for each entry' do
    expect(subject.length).to eq feed.css('entry').length
  end

  [:authors, :pubdate, :source_content_id, :title, :content, :url].each do |field|
    it "should populate #{field} for each content" do
      contents = subject
      has_field = true
      contents.each { |c| has_field = false unless c[field].present? }
      expect(has_field).to be true
    end
  end

  it 'should append the predefined SUFFIX_TEXT' do
    contents = subject
    includes_suffix_text = true
    contents.each { |c| includes_suffix_text = false unless c[:content].include?(SUFFIX_TEXT) }
    expect(includes_suffix_text).to be true
  end

  it 'should extract image data appropriately' do
    contents = subject
    extracts_images = true
    contents.each do |c| 
      html_content = Nokogiri::HTML.parse c[:content]
      unless c[:images].length == html_content.css('img').length 
        extracts_images = false
      end
    end
    expect(extracts_images).to be true
  end
end
