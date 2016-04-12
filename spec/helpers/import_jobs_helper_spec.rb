require 'spec_helper'

describe ImportJobsHelper, type: :helper do
  describe '#alert_class_for_status' do
    context 'Given argument "success"' do
      subject { helper.alert_class_for_status('success') }
      it { is_expected.to eql 'success' }
    end

    context 'Given argument "failed"' do
      subject { helper.alert_class_for_status('failed') }
      it { is_expected.to eql 'error' }
    end

    context 'Given argument "running"' do
      subject { helper.alert_class_for_status('running') }
      it { is_expected.to eql 'info' }
    end

    context 'Given argument "anything else..."' do
      subject { helper.alert_class_for_status('anything else...') }
      it { is_expected.to eql '' }
    end
  end

  describe '#action_button_for_job' do
    let(:job) { ImportJob.new() }
    subject { helper.action_button_for_job(job) }
    before do
      allow(job).to receive(:id).and_return(1)
      allow(job).to receive(:persisted?).and_return(true)
    end

    context 'Given a job with status = "running", and is a import job;' do

      before do
        allow(job).to receive(:status).and_return("running")
      end

      context 'Job type is continuous;' do
        before do
          allow(job).to receive(:job_type).and_return(ImportJob::CONTINUOUS)
        end

        context 'Job has #stop_loop' do
          before do
            allow(job).to receive(:stop_loop).and_return(true)
          end
          it { is_expected.to include('stopping') }
        end

        context 'Job not #stop_loop' do
          before do
            allow(job).to receive(:stop_loop).and_return(false)
          end
          it { is_expected.not_to include('stopping') }
          it { is_expected.to include('Stop Job') }
        end
      end

      context 'Job type not continuous' do
        before do
          allow(job).to receive(:job_type).and_return(nil)
        end

        it { is_expected.to include 'in process' }
      end
    end

    context 'Job status is not running' do
      before do
        allow(job).to receive(:status).and_return('not running')
      end

      context 'Job does not have #next_scheduled_run' do
        before do
          allow(job).to receive(:next_scheduled_run).and_return(nil)
        end

        context 'job #run_at is present' do
          before do
            allow(job).to receive(:run_at).and_return(Time.now)
          end
          it { is_expected.to include 'Schedule Job' }
        end

        context 'job #run_at is not present' do
          before do
            allow(job).to receive(:run_at).and_return(nil)
          end

          it { is_expected.to include 'Run Job' }
        end
      end

      context 'job does have #next_scheduled_run' do
        before do
          allow(job).to receive(:next_scheduled_run).and_return(1.day.from_now)
        end

        it { is_expected.to include 'Cancel Scheduled Runs' }
      end
    end
  end

  describe '#get_path_for_job_action' do
    context 'Job is a PublishJob' do
      let(:job) { PublishJob.new }
      before do
        allow(job).to receive(:id).and_return(1)
        allow(job).to receive(:persisted?).and_return(true)
      end

      context 'action run' do
        subject { helper.get_path_for_job_action('run', job) }

        it { is_expected.to eql run_publish_job_path(job) }
      end

      context 'action cancel' do
        subject { helper.get_path_for_job_action('cancel', job) }

        it { is_expected.to eql cancel_publish_job_path(job) }
      end
    end

    context 'Job is a ImportJob' do
      let(:job) { ImportJob.new }
      before do
        allow(job).to receive(:id).and_return(1)
        allow(job).to receive(:persisted?).and_return(true)
      end

      context 'action run' do
        subject { helper.get_path_for_job_action('run', job) }

        it { is_expected.to eql run_import_job_path(job) }
      end

      context 'action cancel' do
        subject { helper.get_path_for_job_action('cancel', job) }

        it { is_expected.to eql cancel_import_job_path(job) }
      end
    end
  end
end
