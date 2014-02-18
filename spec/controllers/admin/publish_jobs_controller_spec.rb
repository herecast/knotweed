require 'spec_helper'

describe Admin::PublishJobsController do 

  describe "POST 'create'" do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
    end

    describe "on success" do
      before do
        @publish_job_hash = {
          name: "Test Publish Job",
          publish_method: Content::EXPORT_TO_XML
        }
        @query_hash = {
          source_id: ["3"], import_location_id: ["4"],
          from: nil, to: nil, published: nil,
          ids: nil
        }
        post_params = @query_hash.merge({ publish_job: @publish_job_hash })
        post :create, post_params
        @job = PublishJob.first
      end

      it "should redirect to publish jobs path" do
        response.should redirect_to(admin_publish_jobs_path)
      end
      
      it "should properly serialize query params" do
        @job.should_not be_nil
        @job.query_params.should== @query_hash
      end

      it "should register current user as a notifyee of the job" do
        @job.notifyees.include?(@user).should== true
      end

    end
  end


end
