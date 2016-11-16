require 'rails_helper'

RSpec.describe PublishWorker, type: :job do
  describe 'after_enqueue' do
    let(:job) { FactoryGirl.create :publish_job }

    subject { PublishWorker.perform_later(job) }

    it 'should set job attributes' do
      jid = subject.job_id
      expect(job.sidekiq_jid).to eq jid
      expect(job.status).to eq 'scheduled'
    end
  end

  describe 'perform' do
    let(:job) { FactoryGirl.create :publish_job }

    subject { PublishWorker.new.perform(job) }

    describe 'when job errors' do
      before do
        allow(Content).to receive(:contents_query).with(any_args).and_raise StandardError
      end

      it 'should set status to failed' do
        expect{subject}.to change{job.status}.to 'failed'
      end
    end
    
  end
end
