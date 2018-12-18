# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SplitContentForAdPlacement do
  describe '::call' do
    context "when article character total is fewer than #{SplitContentForAdPlacement::CHARACTER_MINIMUM}" do
      before do
        @head = "<p><br><br><br>#{'a' * (SplitContentForAdPlacement::CHARACTER_MINIMUM - 1)}</p><p></p>"
        @tail = nil
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'returns all content in head' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when the first two elements of content are paragraphs' do
      before do
        @head = "<p>#{'a' * SplitContentForAdPlacement::CHARACTER_MINIMUM}</p>"
        @tail = "<p>#{'b' * 280}</p>"
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'head is first paragraph and tail is the rest' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context "when first paragraph is #{SplitContentForAdPlacement::CHARACTER_MINIMUM} characters or fewer" do
      before do
        @head = "<p>#{'a' * (SplitContentForAdPlacement::CHARACTER_MINIMUM - 1)}<br><br></p><p>Glarbity #{'ab' * 270}</p>"
        @tail = '<p>More glarb</p>'
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'head includes the next paragraph as well' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when first paragraph is empty and second is too short' do
      before do
        @head = "<p></p><p>#{'a' * (SplitContentForAdPlacement::CHARACTER_MINIMUM - 1)}</p><p>Glarbity #{'ab' * 270}</p>"
        @tail = '<p>More glarb</p>'
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'head contains first three paragraphs' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when image is after first paragraph' do
      before do
        @head = "<p>#{'a' * SplitContentForAdPlacement::CHARACTER_MINIMUM}</p><div>\n<img><p></p>\n</div><p>#{'ab' * 13}</p>"
        @tail = "<p>#{'b' * 280}</p>"
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'head is all content up to and including first paragraph that is not followed by an image' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when p with content is followed by an empty p and then an image' do
      before do
        @head = "<p>#{'a' * SplitContentForAdPlacement::CHARACTER_MINIMUM}</p><p><b><br></b></p><div><img></div>"
        @tail = nil
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'displays add after the image' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when content is in divs' do
      before do
        @head = "<div>#{'a' * SplitContentForAdPlacement::CHARACTER_MINIMUM}</div>"
        @tail = "<div>#{'b' * 45}</div>"
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'treats <div>s like <p>s' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end

    context 'when no viable content present' do
      before do
        @head = '<br><br><div></div><br>'
        @tail = nil
        @body = "#{@head}#{@tail}"
      end

      subject { SplitContentForAdPlacement.call(@body) }

      it 'defaults to end of article' do
        results = subject
        expect(results[:head]).to eq @head
        expect(results[:tail]).to eq @tail
      end
    end
  end
end
