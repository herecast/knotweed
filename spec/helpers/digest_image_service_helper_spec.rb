# frozen_string_literal: true

require 'spec_helper'

describe DigestImageServiceHelper, type: :helper do
  describe '#digest_image_path' do
    subject do
      helper.digest_image_path('fakeImageUrl.png',
                               width: '100px', height: '100px')
    end

    let(:optimized_path) { 'optimizedPath.png' }
    before do
      allow(ImageUrlService).to receive(:optimize_image_url)
        .with(any_args).and_return(optimized_path)
    end

    it 'should return the optimized image url' do
      expect(subject).to eql optimized_path
    end
  end
end
