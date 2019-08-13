# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecordContentMetric, elasticsearch: true do
  before do
    @content_category = FactoryGirl.build :content_category, name: 'news'
    @news = FactoryGirl.create :content, content_category_id: @content_category.id
  end

  describe '::call' do
    subject do
      RecordContentMetric.call(@news,
                               event_type: 'dummy',
                               current_date: Date.current.to_s)
    end

    context 'when no current report available' do
      it 'creates content report' do
        expect { subject }.to change {
          @news.reload.content_reports.count
        }.by 1
      end
    end

    context 'when current report available' do
      before do
        @news.content_reports << FactoryGirl.create(:content_report)
      end

      it 'does not create content_report' do
        expect { subject }.not_to change {
          @news.reload.content_reports.length
        }
      end
    end

    context 'with event_type: impression' do
      subject do
        RecordContentMetric.call(@news,
                                 event_type: 'impression',
                                 current_date: Date.current.to_s)
      end

      it 'creates impression metric' do
        expect { subject }.to change {
          ContentMetric.where(event_type: 'impression').count
        }.by 1
      end

      it 'increases content view count' do
        expect { subject }.to change {
          @news.reload.view_count
        }.by 1
      end

      it 'increases report view count' do
        subject
        expect(@news.reload.content_reports.last.view_count).to eq 1
      end

      it 'calls for minimal reindex' do
        expect(@news).to receive(:reindex).with(:view_count_data)
        subject
      end
    end

    context 'with event_type: click' do
      subject do
        RecordContentMetric.call(@news,
                                 event_type: 'click',
                                 current_date: Date.current.to_s)
      end

      it 'creates click metric' do
        expect { subject }.to change {
          ContentMetric.where(event_type: 'click').count
        }.by 1
      end

      it 'increases content banner click count' do
        expect { subject }.to change {
          @news.reload.banner_click_count
        }.by 1
      end

      it 'increases report banner click count' do
        subject
        expect(@news.reload.content_reports.last.banner_click_count).to eq 1
      end

      it 'calls for minimal reindex' do
        expect(@news).to receive(:reindex).with(:banner_click_count_data)
        subject
      end
    end
  end
end
