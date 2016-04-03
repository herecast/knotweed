require 'spec_helper'

describe ImportJobsController do 
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  it_behaves_like 'JobController'

  describe "POST 'create'" do 
    before do
      @org = FactoryGirl.create(:organization)
      @parser = FactoryGirl.create(:parser)
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
          organization_id: @org
        }
        post :create, import_job: @import_job_hash, parameters: @parameters
        @job = ImportJob.find_by_parser_id(@parser.id)
      end
    
      it "should redirect to import jobs path" do
        response.should redirect_to(import_jobs_path)
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

  describe 'GET index' do
    before { @jobs = FactoryGirl.create_list :import_job, 3 }
    subject! { get :index }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end

    it 'should load the import jobs' do
      assigns(:import_jobs).should eq @jobs
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end
  end

  describe 'GET edit' do
    before { @job = FactoryGirl.create :import_job }
    subject! { get :edit, id: @job.id }

    it 'should respond with a 200 status' do
      response.code.should eq '200'
    end
  end
end
