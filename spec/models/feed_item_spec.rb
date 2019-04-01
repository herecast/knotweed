# frozen_string_literal: true

require 'spec_helper'

describe FeedItem do
  describe 'initialize' do
    subject { FeedItem.new(obj) }

    describe 'for an organization' do
      let(:obj) { FactoryGirl.create :organization }
      it 'should set model_type to `organization`' do
        expect(subject.model_type).to eq 'organization'
      end

      it 'should set the `organization` to obj' do
        expect(subject.organization).to eq obj
      end
    end

    describe 'for a `Carousel`' do
      let(:obj) { Carousel.new }
      it 'should set model_type to `carousel`' do
        expect(subject.model_type).to eq 'carousel'
      end

      it 'should set the `carousel` to obj' do
        expect(subject.carousel).to eq obj
      end
    end

    describe 'for serialized content' do
      let(:obj) { double(class: Hashie::Mash, id: 123) }
      it 'should set model_type to `content`' do
        expect(subject.model_type).to eq 'content'
      end

      it 'should set the `content` to obj' do
        expect(subject.content).to eq obj
      end
    end
  end
end
