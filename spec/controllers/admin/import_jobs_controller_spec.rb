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
    
    it "should save parameters as serialized Hash" do 
      parameters = {
          "#{@parser.parameters[0].name.downcase.gsub(" ", "_")}" => "param 1 val",
          "#{@parser.parameters[1].name.downcase.gsub(" ", "_")}" => "param 2 val"
        }
      post :create, import_job: { 
        name: "Test Job",
        source_path: "Test Path",
        parser_id: @parser.id,
        organization_id: @parser.organization.id
        }, parameters: parameters
      response.should redirect_to(admin_import_jobs_path)
      job = ImportJob.find_by_parser_id(@parser.id)
      job.should_not be_nil
      job.config.should== parameters
    end
    
  end
end
