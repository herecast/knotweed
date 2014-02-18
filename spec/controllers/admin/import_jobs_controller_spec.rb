require 'spec_helper'

describe Admin::ImportJobsController do 
  
  describe "POST 'create'" do 
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
      @org = FactoryGirl.create(:organization)
      @parser = FactoryGirl.create(:parser, organization: @org)
      2.times do 
        FactoryGirl.create(:parameter, parser: @parser)
      end
    end

    describe "on success" do
      before do
        @parameters = {
            "#{@parser.parameters[0].name.downcase.gsub(" ", "_")}" => "param 1 val",
            "#{@parser.parameters[1].name.downcase.gsub(" ", "_")}" => "param 2 val"
        }
        @import_job_hash = {
          name: "Test Job",
          source_path: "Test Path",
          parser_id: @parser.id,
          organization_id: @parser.organization.id
        }
        post :create, import_job: @import_job_hash, parameters: @parameters
        @job = ImportJob.find_by_parser_id(@parser.id)
      end
    
      it "should redirect to import jobs path" do
        response.should redirect_to(admin_import_jobs_path)
      end

      it "should save parameters as serialized Hash" do 
        @job.should_not be_nil
        @job.config.should== @parameters
      end

      it "should register current user as a notifyee of the job" do
        @job.should_not be_nil
        @job.notifyees.include?(@user).should== true
      end
    end
    
  end
end
