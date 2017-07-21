# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_uri            :string(255)
#  job_type              :string(255)
#  organization_id       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  status                :string(255)
#  frequency             :integer          default(0)
#  archive               :boolean          default(FALSE), not null
#  content_set_id        :integer
#  run_at                :datetime
#  stop_loop             :boolean          default(TRUE)
#  automatically_publish :boolean          default(FALSE)
#  repository_id         :integer
#  publish_method        :string(255)
#  sidekiq_jid           :string
#  next_scheduled_run    :datetime
#  inbound_prefix        :string
#  outbound_prefix       :string
#

require 'spec_helper'

describe ImportJob, :type => :model do

  describe '#set_stop_loop' do
    let(:import_job) { FactoryGirl.create :import_job, job_type: ImportJob::RECURRING }

    context 'when import_job is first saved as continuous' do
      subject { import_job.update job_type: ImportJob::CONTINUOUS }

      it { expect{subject}.to change{import_job.stop_loop}.to false }
    end

    context "when import_job is already continuous" do
      let(:import_job) { FactoryGirl.create :import_job, job_type: ImportJob::CONTINUOUS }

      subject { import_job.update stop_loop: true }

      it 'should allow changing stop_loop' do
        expect{subject}.to change{import_job.stop_loop}.to true
      end

      context 'and is changed to not be continuous' do
        subject { import_job.update job_type: ImportJob::RECURRING }

        it 'should change stop_loop to true' do
          expect{subject}.to change{import_job.stop_loop}.to true
        end
      end
    end

  end

  describe '#cancel_scheduled_runs' do
    context 'status is "scheduled"' do
      let!(:sidekiq_job) { double({ delete: nil }) }
      let!(:sidekiq_set) { double({ select: [sidekiq_job] }) }

      let!(:stubs) do 
        allow(Sidekiq::ScheduledSet).to receive(:new).and_return(sidekiq_set)
      end

      it 'changes status to ""' do
        subject.status = "scheduled"
        expect { subject.cancel_scheduled_runs }.to change{ subject.status }.to nil
      end

      it 'should call delete directly on the sidekiq job' do
        expect(sidekiq_job).to receive(:delete).with(any_args)
        subject.cancel_scheduled_runs
      end
    end
  end
end
