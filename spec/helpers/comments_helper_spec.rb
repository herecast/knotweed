# frozen_string_literal: true

require 'spec_helper'

describe CommentsHelper, type: :helper do
  describe '#sanitize_comment_content' do
    subject { helper.sanitize_comment_content(sample_text) }
    let(:sample_text) { '<p>Hello, blah blah, <br /> blah blah blah </p>' }

    it 'should remove p tags' do
      expect(subject).to_not include('<p>', '</p>')
    end

    it 'should remove br tags' do
      expect(subject).to_not include('<br />')
    end
  end
end
