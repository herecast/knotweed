require 'spec_helper'

describe PublishJob do

  describe "contents count" do
    before do
      @publication = FactoryGirl.create(:publication)
      FactoryGirl.create_list(:content, 3, source: @publication)
      FactoryGirl.create_list(:content, 5)
      @job = FactoryGirl.create(:publish_job)
      @repo = FactoryGirl.create(:repository)
    end

    it "should return the total number of contents when no query provided" do
      @job.contents_count.should== Content.count
    end

    it "should return the correct number of matching contents" do
      @job.query_params[:source_id] = [@publication.id]
      @job.save!
      @job.contents_count.should== Content.where(source_id: @publication.id).count
    end

    it "should return only the ids listed if any ids are in the query" do
      @job.query_params[:source_id] = [@publication.id]
      @job.save!
      @job.contents_count.should > 1
      @job.query_params[:ids] = "#{Content.last.id}"
      @job.save!
      @job.contents_count.should== 1
    end

    it "should return only the contents already published to the specified repo" do
      @job.query_params[:repository_id] = @repo.id
      @job.query_params[:published] = "true"
      @job.save!
      contents = FactoryGirl.create_list(:content, 3)
      @repo.contents << contents
      @job.contents_count.should== 3
    end

    it "should return all contents matching the query that are not published to the specified repo when published is false" do
      @job.query_params[:repository_id] = @repo.id
      @job.query_params[:published] = "false"
      @job.save!
      @job.contents_count.should== Content.count - @repo.contents.count
    end
  end

  describe "perform job" do
    before do
      @job = FactoryGirl.create(:publish_job, publish_method: Content::EXPORT_TO_XML)
      FactoryGirl.create_list(:content, 3)
      @job.enqueue_job
      successes, failures = Delayed::Worker.new(:max_priority => nil,
        :min_priority => nil,
        :quiet => false, 
        :queues => ["imports", "publishing"]).work_off
    end
    after do
      #clean up output folder
      system("rm -rf #{Figaro.env.content_export_path}/*")
    end

    it "should succeed and set status to success" do
      job = PublishJob.find(@job.id)
      job.status.should== "success"
    end

    it "should publish the contents via desired method (export to xml)" do
      c = Content.first
      File.exists?("#{c.export_path}/#{c.guid}.xml").should be_true
      File.exists?("#{c.export_path}/#{c.guid}.html").should be_true
    end

    it "should create a publish record attached to the job" do
      PublishRecord.count.should== 1
      PublishRecord.first.publish_job.should== @job
    end

    it "should assign any contents published to the attached publish record" do
      record = PublishRecord.first
      record.contents.count.should== Content.count
    end
      
  end

end
