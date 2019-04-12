require 'spec_helper'

RSpec.describe 'Content Moderations Endpoints', type: :request do
  describe 'POST /contents/:content_id/moderate' do
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
    end

    let(:auth_headers) { auth_headers_for(@user) }

    subject {
      post "/api/v3/contents/#{@content.id}/moderate",
        params: { id: @content.id, flag_type: 'Inappropriate' },
        headers: auth_headers
    }

    it 'should queue flag notification email' do
      expect { subject }.to change{
        ActiveJob::Base.queue_adapter.enqueued_jobs.size
      }.by(1)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:job]).to eq(ActionMailer::DeliveryJob)
    end
  end
end