# frozen_string_literal: true

require 'spec_helper'

describe DigestImageServiceHelper, type: :helper do
  describe '#digest_image_path' do
    subject { helper.digest_image_path('fakeImageUrl.png',
                                       { width: '100px', height: '100px' }) }

    let(:optimized_path) { 'optimizedPath.png' }
    before { allow(ImageUrlService).to receive(:optimize_image_url).
             with(any_args).and_return(optimized_path) }

    it 'should return the optimized image url' do
      expect(subject).to eql optimized_path
    end
  end
end
