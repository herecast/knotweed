# == Schema Information
#
# Table name: import_jobs
#
#  id                    :integer          not null, primary key
#  parser_id             :integer
#  name                  :string(255)
#  config                :text
#  source_path           :string(255)
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
#

require 'spec_helper'

describe ImportJob do

  describe "perform job" do
    before do
      prerender_cache_stub
      # note we need sufficient entries in the config hash here for the 
      # output to validate.
      @config = { "timestamp" => "2011-06-07T12:25:00", "guid" => "100", "other_param" => "hello", "pubdate" => "2011-06-07T12:25:00",
                  "source" => "not empty", "title" => "      not empty and with whitespace  ",
                  "content" => "<p> </p> <p> </p> Content begins here" }
      @parser = FactoryGirl.create(:parser, filename: "test/parser_that_outputs_config.rb")
      @consumer_apps = FactoryGirl.create_list :consumer_app, 2
      @job = FactoryGirl.create(:import_job, parser: @parser, config: @config, consumer_apps: @consumer_apps)
      # run job via delayed_job hooks (even though delayed_job doesnt run in tests)
      @job.enqueue_job
      # another job whose output fails validation
      @config2 = { "guid" => "101", "other_param" => "hello" }
      @job2 = FactoryGirl.create(:import_job, parser: @parser, config: @config2)
      @job2.enqueue_job
      successes, failures = Delayed::Worker.new(:max_priority => nil,
        :min_priority => nil,
        :quiet => false, 
        :queues => ["imports", "publishing"]).work_off
    end

    it "should succeed and set status to success" do
      # confirm DJ thinks job succeeded
      job = ImportJob.find(@job.id)
      job.status.should== "success"
    end

    it "should create an import record attached to the job" do
      ImportRecord.count.should== 2
      ImportRecord.where(import_job_id: @job.id).count.should==1
      record = ImportRecord.where(import_job_id: @job.id).first
      @job.last_import_record.should== record
    end

    it "should create a new Content entry" do
      # 2 since we've run two jobs with two different configs here
      # also note that @config["title"] has to be stripped
      # to confirm the import job is stripping all data fields before
      # passing it to Content
      Content.count.should== 2
      Content.where(title: @config["title"].strip).count.should== 1
      Content.where(timestamp: nil).count.should== 1
    end

    it "should strip empty p tags from the beginning of content" do
      c = Content.where(title: @config["title"].strip).first
      c.content.include?("<p> </p>").should == false
    end

    it "should send a request to prerender recache" do 
      expect(WebMock).to have_requested(:post, "http://api.prerender.io/recache").twice
    end

  end

end
