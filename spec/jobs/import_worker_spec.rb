require 'rails_helper'

RSpec.describe ImportWorker, type: :job do
  describe 'after_enqueue' do
    let(:job) { FactoryGirl.create :import_job }

    subject { ImportWorker.perform_later(job) }

    it 'should set job attributes' do
      jid = subject.job_id
      expect(job.sidekiq_jid).to eq jid
      expect(job.status).to eq 'scheduled'
    end

    context 'scheduled in the future' do
      # need to usec: 0 or else sidekiq changes it ever so slightly 
      # and we run into equality problems
      before { @date = 3.hours.from_now.change(usec: 0) }
      subject { ImportWorker.set(wait_until: @date).perform_later(job) }

      it 'should set next_scheduled_run on the job' do
        subject
        expect(job.next_scheduled_run).to eq(@date)
      end
    end

    context 'for a continuous job' do
      before { job.update job_type: ImportJob::CONTINUOUS }

      it 'should set status to "running"' do
        expect{subject}.to change{job.status}.to 'running'
      end
    end
  end

  describe 'handle_error', inline_jobs: true do
    let(:exception) { StandardError }
    # cause it to error after the log is defined on a line that
    # is always called
    before { allow_any_instance_of(ImportWorker).to receive(:process_data).and_raise(exception) }

    let(:job) { FactoryGirl.create :import_job }

    subject { ImportWorker.new.perform(job) }

    it 'should update the job record' do
      begin
        subject
      rescue
      end
      expect(job.status).to eq 'failed'
    end
  end

  describe 'import filter' do
    let(:parser) { FactoryGirl.create(:parser, filename: "test/parser_that_outputs_config.rb") }
    let(:job) { FactoryGirl.create :import_job, parser: parser, config: config }

    subject { ImportWorker.new.perform(job) }

    context 'when article has content id' do
      # has to be with a bang or the Content.count change expectation doesn't work out
      let!(:content) { FactoryGirl.create :content, channel_id: 1 }
      let(:config) { { 'X-Original-Content-Id' => content.id } }

      it 'should not create new content' do
        expect{subject}.to_not change{Content.count}
      end

      it 'should log a record as filtered' do
        subject
        expect(job.last_import_record.filtered).to eq 1
      end
    end

    context 'when article has event instance id' do
      let(:event) { FactoryGirl.create :event, channel_id: 1 }
      let!(:event_instance) { FactoryGirl.create :event_instance, event_id: event.id }
      let(:config) { { 'X-Original-Event-Instance-Id' => event_instance.id } }

      it 'should not create new content' do
        expect{subject}.to_not change{Content.count}
      end

      it 'should log a record as filtered' do
        subject
        expect(job.last_import_record.filtered).to eq 1
      end
    end
  end

  describe 'perform' do
    let(:parser) { FactoryGirl.create(:parser, filename: "test/parser_that_outputs_config.rb") }
    let(:config) { { "timestamp" => "2011-06-07T12:25:00", "guid" => "100", 
      "other_param" => "hello", "pubdate" => "2011-06-07T12:25:00",
      "source" => "not empty", "title" => "      not empty and with whitespace  ",
      "content" => "<p> </p> <p> </p> Content begins here" } }
    let(:job) { FactoryGirl.create :import_job, parser: parser, config: config }

    subject { ImportWorker.new.perform(job) }

    it 'should succeed' do
      subject
      expect(job.status).to eq 'success'
    end

    it 'should create an import record' do
      expect{subject}.to change{job.import_records.count}.by 1
    end

    it 'should create a Content record' do
      expect{subject}.to change{Content.count}.by 1
      expect(Content.last.title).to eq config['title'].strip
    end

    context 'when DSP is backing up' do
      before do
        allow(ImportJob).to receive(:backup_start).and_return(Time.current - 10)
        allow(ImportJob).to receive(:backup_end).and_return(Time.current + 10)
      end

      it 'should reschedule the job for after backup' do
        subject
        expect(job.next_scheduled_run.to_i).to eq ImportJob.backup_end.to_i
      end
    end

    describe 'recurring jobs' do
      before do
        Timecop.freeze
        job.update job_type: ImportJob::RECURRING, frequency: 60
      end
      after { Timecop.return }

      it 'should update the job attributes with scheduling' do
        expect{subject}.to change{job.sidekiq_jid}
        expect(job.status).to eq 'scheduled'
        expect(job.next_scheduled_run).to be > Time.current
      end

      # ActiveJob queueing does some weird stuff with .00000x the sixth decimal place
      # of float times for scheduling. It's not totally predictable, and we don't care about
      # it, so we need to do this funky matching to successfully pass here even though it
      # would be much nicer to use "have_enqueued_job"
      it 'should schedule the job with sidekiq' do
        subject
        expect(Time.at(ActiveJob::Base.queue_adapter.enqueued_jobs.first[:at]).to_i).to \
          eq (Time.current+60.minutes).to_i
      end
    end

    describe 'continuous jobs' do
      before do
        job.update job_type: ImportJob::CONTINUOUS
        Timecop.freeze
      end
      after { Timecop.return }

      it 'should re-run the job in 5 seconds' do
        expect(ImportWorker).to receive(:set).with({wait_until: 5.seconds.from_now}).
          and_return(ImportWorker.set(wait_until: 5.seconds.from_now))
        subject
      end

      context 'with stop_loop set to true' do
        before do
          job.update_attribute :stop_loop, true
        end

        it 'should not re-run the job in 5 seconds' do
          expect(ImportWorker).to_not receive(:set).with({wait_until: 5.seconds.from_now})
          subject
        end

        it 'should set the success attributes' do
          subject
          expect(job.stop_loop).to be false
          expect(job.status).to eq 'success'
          expect(job.sidekiq_jid).to be nil
        end
      end
    end
  end
end
