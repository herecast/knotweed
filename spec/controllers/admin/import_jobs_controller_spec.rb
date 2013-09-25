require 'spec_helper'

describe Admin::ImportJobsController do 
  
  describe "POST 'create'" do 
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
      @parser = FactoryGirl.create(:parser)
      2.times do 
        FactoryGirl.create(:parameter, parser: @parser)
      end
    end
    
    it "should compile parameters into a YAML formatted config field" do
      params = {
          "#{@parser.parameters[0].name.downcase.gsub(" ", "_")}" => "param 1 val",
          "#{@parser.parameters[1].name.downcase.gsub(" ", "_")}" => "param 2 val"
        }
      post :create, import_job: { 
        name: "Test Job",
        source_path: "Test Path",
        parser_id: @parser.id,
        organization_id: @parser.organization.id
        }, parameters: params
      response.should redirect_to(admin_import_jobs_path)
      job = ImportJob.find_by_parser_id(@parser.id)
      job.should_not be_nil
      job.config.should== params.to_yaml
    end
    
  end
end