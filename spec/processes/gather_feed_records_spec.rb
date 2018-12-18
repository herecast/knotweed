# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GatherFeedRecords, elasticsearch: true do
  describe '::call' do
    before do
      @content = FactoryGirl.create :content, :news
    end

    let(:params) do
      {}
    end

    subject do
      GatherFeedRecords.call(
        params: params,
        current_user: nil
      )
    end

    it 'returns restructured payload' do
      response = subject
      expect(response[:records][0].to_json).to include_json(
        model_type: 'content',
        id: @content.id
      )
      expect(response[:records][0].content.id).to eq @content.id
    end

    it 'alerts product team of new content' do
      allow(BackgroundJob).to receive(:perform_later).with('ManageContentOnFirstServe').and_return true
      expect(BackgroundJob).to receive(:perform_later).with('ManageContentOnFirstServe', 'call', any_args)
      subject
    end

    context 'with location_id passed' do
      before do
        @loc1 = FactoryGirl.create :location
        @loc2 = FactoryGirl.create :location
        @content.update_attribute(:location_id, @loc1.id)
        @other_content = FactoryGirl.create :content, :news # NOT IN A LOCATION
        @other_content.reload.reindex
        @content.reload.reindex
      end

      context 'matching the content' do
        let(:params) { { location_id: @loc1.id } }

        it 'should return the content' do
          response = subject
          expect(response[:records][0].content.id).to eq @content.id
        end

        it 'should not return the other content' do
          response = subject
          expect(response[:records].length).to eq 1
        end
      end

      context 'not matching the content' do
        let(:params) { { location_id: @loc2.id } }

        it 'should not return the content' do
          response = subject
          expect(response[:total_entries]).to eq 0
        end
      end
    end
  end
end
