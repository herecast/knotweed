require 'spec_helper'

describe PublishJob do

  describe "contents count" do
    before do
      @publication = FactoryGirl.create(:publication)
      FactoryGirl.create_list(:content, 3, source: @publication)
      FactoryGirl.create_list(:content, 5)
      @job = FactoryGirl.create(:publish_job)
    end

    it "should return the total number of contents when no query provided" do
      @job.contents_count.should== Content.count
    end

    it "should return the correct number of matching contents" do
      @job.query_params[:source_id] = [@publication.id]
      @job.save!
      @job.contents_count.should== Content.where(source_id: @publication.id).count
    end
  end

  describe "perform job" do
    before do
      @job = FactoryGirl.create(:publish_job, publish_method: PublishJob::EXPORT_TO_XML)
      FactoryGirl.create_list(:content, 3)
      @job.enqueue_job
    end
    after do
      #clean up output folder
      system("rm -rf #{Figaro.env.content_export_path}/*")
    end

    it "should succeed and set status to success" do
      @job.status.should== "success"
    end

    it "should publish the contents via desired method (export to xml)" do
      c = Content.first
      File.exists?("#{c.export_path}/#{c.guid}.xml").should be_true
      File.exists?("#{c.export_path}/#{c.guid}.html").should be_true
    end
  end

end
