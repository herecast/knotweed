require "spec_helper"

describe JobMailer, :type => :mailer do

  describe "error email" do
    include ActiveJob::TestHelper

    let(:error_parser) { FactoryGirl.create(:parser, filename: "test/parser_that_errors.rb") }
    let(:job) { FactoryGirl.create(:import_job, parser: error_parser, source_uri: "http://www.google.com") }
    let(:user) { FactoryGirl.create :user }

    before { job.notifyees << user }

    subject { ImportWorker.new.perform(job) }

    it "should fail and should send error email" do
      expect {
        begin
          subject
        rescue
        end
      }.to change{ActiveJob::Base.queue_adapter.enqueued_jobs.size}.by(1)
      delivery_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(delivery_job[:job]).to eq(ActionMailer::DeliveryJob)
      perform_delayed_mailing(delivery_job)
      expect(JobMailer.deliveries.last.to.include?(user.email)).to eq(true)
      expect(job.status).to eq("failed")
    end
      
  end


  def perform_delayed_mailing(job)
    passivated_job = convert_gids_in_job(job)
    perform_enqueued_jobs { ActionMailer::DeliveryJob.perform_now(*passivated_job[:args]) }
  end

  def convert_gids_in_job(job)
    job.tap { |j|
      job_args    = j[:args]

      # There is a global ID at index 3.
      gid         = job_args[3]["_aj_globalid"]
      job_args[3] = GlobalID::Locator.locate(gid)
    }
  end
end
