require 'spec_helper'

describe ImportJob do

  describe "validation" do
    it "should ensure parser belongs to same organization or is universal" do
      @org1 = FactoryGirl.create(:organization)
      @org2 = FactoryGirl.create(:organization)
      @parser = FactoryGirl.create(:parser, organization: @org1)
      @univ_parser = FactoryGirl.create(:parser, organization: nil)
      FactoryGirl.build(:import_job, organization: @org2, parser: @parser).should_not be_valid
      FactoryGirl.build(:import_job, organization: @org2, parser: @univ_parser).should be_valid
      FactoryGirl.build(:import_job, organization: @org1, parser: @parser).should be_valid
    end
  end

  describe "perform job" do
    before do
      # note we need sufficient entries in the config hash here for the 
      # output to validate.
      @config = { "timestamp" => "2011-06-07T12:25:00", "guid" => "100", "other_param" => "hello", "pubdate" => "2011-06-07T12:25:00",
                  "source" => "not empty", "title" => "not empty"}
      @parser = FactoryGirl.create(:parser, filename: "parser_that_outputs_config.rb")
      @job = FactoryGirl.create(:import_job, parser: @parser, config: @config.to_yaml)
      # run job via delayed_job hooks (even though delayed_job doesnt run in tests)
      @job.enqueue_job
      # another job whose output fails validation
      @config2 = { "guid" => "101", "other_param" => "hello" }
      @job2 = FactoryGirl.create(:import_job, parser: @parser, config: @config2.to_yaml)
      @job2.enqueue_job
    end

    it "should succeed and set status to success" do
      # confirm DJ thinks job succeeded
      @job.status.should== "success"
    end

    it "should create an import record attached to the job" do
      ImportRecord.count.should== 2
      ImportRecord.where(import_job_id: @job.id).count.should==1
      record = ImportRecord.where(import_job_id: @job.id).first
      @job.last_import_record.should== record
    end

    it "should create a new Content entry" do
      # 2 since we've run two jobs with two different configs here
      Content.count.should== 2
      Content.where(title: @config["title"]).count.should== 1
      Content.where(timestamp: nil).count.should== 1
    end

  end

end
