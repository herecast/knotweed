require 'spec_helper'

RSpec.describe 'Content Moderations Endpoints', type: :request do
  describe 'POST /moderations' do
    let!(:content) { FactoryGirl.create :content }
    let(:user) { FactoryGirl.create :user }
    let(:auth_headers) { auth_headers_for(user) }

    subject {
      post "/api/v3/moderations",
        params: { id: content.id, content_type: 'content', flag_type: 'Inappropriate' },
        headers: auth_headers
    }

    it 'should queue flag notification email' do
      expect { subject }.to change{
        ActiveJob::Base.queue_adapter.enqueued_jobs.size
      }.by(1)
    end
  end
end
