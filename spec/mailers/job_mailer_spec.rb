require "spec_helper"

describe JobMailer do

  describe "error email" do
    before do
      @error_parser = FactoryGirl.create(:parser, filename: "parser_that_errors.rb")
      @job = FactoryGirl.create(:import_job, parser: @error_parser, source_path: "www.google.com")
      @user = FactoryGirl.create(:user)
      @job.notifyees << @user
      @job.enqueue_job
    end

    it "should fail and should send error email" do
      successes, failures = Delayed::Worker.new(:max_priority => nil,
        :min_priority => nil,
        :quiet => false, 
        :queues => ["imports", "publishing"]).work_off
      failures.should== 1
      job = @job.class.find(@job.id)
      job.status.should== "failed"
      JobMailer.deliveries.present?.should== true
      JobMailer.deliveries.last.to.include?(@user.email).should== true
    end
      
  end

end
