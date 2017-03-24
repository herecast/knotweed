require 'spec_helper'

RSpec.describe ImageUrlService do
  around(:each) do |example|
    old_uri                    = ENV["OPTIMIZED_IMAGE_URI"]
    ENV["OPTIMIZED_IMAGE_URI"] = "http://thumbor.subtext.org"

    example.run

    ENV["OPTIMIZED_IMAGE_URI"] = old_uri
  end

  subject { ImageUrlService }

  it { is_expected.to respond_to(:optimize_image_urls) }
  it { is_expected.to respond_to(:optimize_image_url ) }

  describe "#optimize_image_url" do
    it 'returns the given URL if the given URL is blank' do
      expect(subject.optimize_image_url(url: nil, width: 100, height: 100, do_crop: true)).to eq nil
      expect(subject.optimize_image_url(url: "",  width: 100, height: 100, do_crop: true)).to eq ""
    end

    it 'returns the given URL if the given URL is not an HTTP url' do
      expect(subject.optimize_image_url(url: 'non-http-url', width: 100, height: 100, do_crop: true)).to eq 'non-http-url'
    end

    it 'returns the given URL if the given rectangle has no value' do
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: nil, height: 100, do_crop: true)).to eq 'http://knotweed.s3.amazonaws.com'
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: nil, do_crop: true)).to eq 'http://knotweed.s3.amazonaws.com'
    end

    it 'returns a URL' do
      expect(is_url(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: true ))).to eq true
      expect(is_url(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: false))).to eq true
    end

    it 'returns a new URL, different from the given URL' do
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: true )).to_not eq 'http://knotweed.s3.amazonaws.com'
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: false)).to_not eq 'http://knotweed.s3.amazonaws.com'
    end

    it 'the returned URL depends on the cropping choice' do
      non_cropped_result = subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: false)
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: true )).to_not eq non_cropped_result
    end

    it 'the returned URL depends on the target rectangle' do
      result1 = subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: true)
      expect(   subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 200, do_crop: true )).to_not eq result1
      expect(   subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 200, height: 100, do_crop: true )).to_not eq result1

      result2 = subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 200, height: 100, do_crop: true)
      expect(   subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 200, do_crop: true )).to_not eq result2
    end

    it 'returns the given URL if the URL has an unknown hostname' do
      expect(subject.optimize_image_url(url: 'http://unknown.hostname.com',      width: 100, height: 100, do_crop: true )).to     eq 'http://unknown.hostname.com'
      expect(subject.optimize_image_url(url: 'http://knotweed.s3.amazonaws.com', width: 100, height: 100, do_crop: true )).to_not eq 'http://knotweed.s3.amazonaws.com'
    end
  end

  describe "#optimize_image_urls" do
    let(:text) { "<div><img src=\"http://knotweed.s3.amazonaws.com/asdf/wer.png\" style=\"width: 75%; min-width: 30px\" height=\"100\" /></div>" }

    it 'replaces img URLs' do
      expect(subject.optimize_image_urls(html_text: text)).to include "#{ENV['OPTIMIZED_IMAGE_URI']}/unsafe/30x100/smart"
    end
  end

  def is_url(s)
    !!(s =~ /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/)
  end
end
