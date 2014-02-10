require 'spec_helper'

describe Admin::PublishJobsController do 
  before do
    @user = FactoryGirl.create(:admin)
    sign_in @user
  end

  describe "POST 'create'" do
    it "should properly serialize query params" do
      post_params = { publish_job: {
        name: "Test Publish Job",
        publish_method: PublishJob::EXPORT_TO_XML },
        source_id: ["3"], import_location_id: ["4"],
        from: nil, to: nil, published: nil,
        ids: nil}
        
      post :create, post_params
      response.should redirect_to(admin_publish_jobs_path)
      job = PublishJob.first
      job.should_not be_nil
      post_params.delete(:publish_job)
      job.query_params.should== post_params
    end
  end


end
