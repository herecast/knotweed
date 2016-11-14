require "spec_helper"

describe JobMailer, :type => :mailer do

  describe "error email" do
    let(:error_parser) { FactoryGirl.create(:parser, filename: "test/parser_that_errors.rb") }
    let(:job) { FactoryGirl.create(:import_job, parser: error_parser, source_path: "http://www.google.com") }
    let(:user) { FactoryGirl.create :user }

    before { job.notifyees << user }

    subject { ImportWorker.new.perform(job) }

    it "should fail and should send error email" do
      begin
        subject
      rescue
      end
      expect(job.status).to eq("failed")
      expect(JobMailer.deliveries.present?).to eq(true)
      expect(JobMailer.deliveries.last.to.include?(user.email)).to eq(true)
    end
      
  end

end
