require 'spec_helper'

# NOTE: this parser is designed for a specific RSS feed available at
#   raunerlibrary.blogspot.com/feeds/posts/default
# I'm deliberately not loading that into a fixture file here so that this
# spec will alert us if that changes, since that will break the parser.
describe 'Rauner Library RSS Feed Parser' do
  before do
    WebMock.allow_net_connect!
    load File.join(Rails.root, 'lib', 'parsers', 'rauner_rss_feed.rb')
  end
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
      contents.each { |c| has_field = c[field].present? }
      expect(has_field).to be true
    end
  end

  it 'should append the post\'s URL to its content' do
    contents = subject
    includes_url = true
    contents.each { |c| includes_url = c[:content].include?(c[:url]) }
    expect(includes_url).to be true
  end
end
