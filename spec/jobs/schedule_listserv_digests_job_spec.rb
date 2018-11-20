require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ScheduleListservDigestsJob do

  subject{ described_class.new.perform }

  context 'When listserv records exists, enabled and have digest send time' do
    let!(:listserv1) { FactoryGirl.create :listserv,
                       digest_send_time: "02:00",
                       send_digest: true,
                       digest_reply_to: 'test@example.org'
    }

    let!(:listserv2) { FactoryGirl.create :listserv,
                       digest_send_time: "06:00",
                       send_digest: true,
                       digest_reply_to: 'test@example.org'
    }

    it 'triggers ListservDigestJob for listserv records' do
      expect{ subject }.to have_enqueued_job(ListservDigestJob).exactly(2).times
    end

    it 'schedules them for their send times' do
      Timecop.freeze(Time.current.beginning_of_day) do
        subject
        queue = ActiveJob::Base.queue_adapter.enqueued_jobs

        first_time = listserv1.next_digest_send_time
        expect(queue.select{|j| j[:at] == first_time.to_i}.first).to_not be nil

        second_time = listserv2.next_digest_send_time
        expect(queue.select{|j| j[:at] == second_time.to_i}.first).to_not be nil
      end
    end

    context 'when retry list has job w/ no argument' do
      before do
        no_arg_job = double(args: [])
        allow(Sidekiq::RetrySet).to receive(:new).and_return([no_arg_job])
      end

      it "enqueues job" do
        Timecop.freeze(Time.current.beginning_of_day) do
          subject
          queue = ActiveJob::Base.queue_adapter.enqueued_jobs

          first_time = listserv1.next_digest_send_time
          expect(queue.select{|j| j[:at] == first_time.to_i}.first).to_not be nil
        end
      end
    end
  end

  context 'When listserv records exist, but not enabled' do
    let!(:listserv) { FactoryGirl.create :listserv,
                       digest_send_time: "02:00",
                       send_digest: false}

    it 'does not schedule them for digest generation' do
      expect{ subject }.to_not have_enqueued_job(ListservDigestJob)
    end
  end

  context 'when ran multiple times' do
    around(:each) do |example|
      prev_qu_adapter = ActiveJob::Base.queue_adapter
      Sidekiq::Testing.disable!
      ActiveJob::Base.queue_adapter = :sidekiq
      example.run
      Sidekiq.redis { |conn| conn.flushdb }
      ActiveJob::Base.queue_adapter = prev_qu_adapter
    end

    let!(:listserv) { FactoryGirl.create :listserv,
                       digest_send_time: "02:00",
                       digest_reply_to: 'test@example.org',
                       send_digest: true}

    it 'does not schedule the same job more than once' do
      expect{described_class.new.perform}.to change{
        Sidekiq::ScheduledSet.new.count
      }.by(1)

      expect{described_class.new.perform}.not_to change{
        Sidekiq::ScheduledSet.new.count
      }
    end
  end
end
