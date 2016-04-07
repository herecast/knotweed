require 'spec_helper'

describe PublishJobsController, :type => :controller do 

  describe "POST 'create'" do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
    end

    describe "on success" do
      before do
        @repo = FactoryGirl.create(:repository)
        @publish_job_hash = {
          name: "Test Publish Job",
          publish_method: Content::EXPORT_TO_XML
        }
        @query_hash = {
          organization_id: ["3"], import_location_id: ["4"],
          from: nil, to: nil, published: nil,
          ids: nil, content_category_id: nil,
          repository_id: FactoryGirl.create(:repository).id.to_s
        }
        post_params = @query_hash.merge({ publish_job: @publish_job_hash })
        post :create, post_params
        @job = PublishJob.first
      end

      it "should redirect to publish jobs path" do
        expect(response).to redirect_to(publish_jobs_path)
      end
      
      it "should properly serialize query params" do
        expect(@job).not_to be_nil
        expect(@job.query_params).to eq(@query_hash)
      end

      it "should register current user as a notifyee of the job" do
        expect(@job.notifyees.include?(@user)).to eq(true)
      end

    end
  end

  describe 'GET index' do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
      @jobs = FactoryGirl.create_list :publish_job, 3
    end

    subject! { get :index }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the publish jobs' do
      expect(assigns(:publish_jobs)).to eq @jobs
    end
  end

  describe ' GET edit' do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @job = FactoryGirl.create :publish_job
    end

    subject! { get :edit, id: @job.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the publish job' do
      expect(assigns(:publish_job)).to eq @job
    end
  end

  describe "GET 'file_archive'" do
    context "with a completed job with a file_archive" do
      before do
        @job = FactoryGirl.create(:publish_job, publish_method: Content::EXPORT_TO_XML)
        repo = FactoryGirl.create(:repository)
        @job.query_params[:repository_id] = repo.id

        FactoryGirl.create_list(:content, 3)
        @job.before @job
        @job.perform
      end

      after do
        system("rm -rf #{Content::TMP_EXPORT_PATH}/*")
        FileUtils.rm_rf(File.join("public", "exports"))
      end

      context "with a logged in user" do
        before do
          @user = FactoryGirl.create(:admin)
          sign_in @user
        end

        it "should return a file download" do
          get :file_archive, { id: @job.id }
          expect(response.body).to eq(IO.binread(@job.file_archive))
        end
      end

      context "without logging in" do
        it "should redirect to sign in" do
          get :file_archive, { id: @job.id }
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "with a job without a file_archive" do
      before do
        @job = FactoryGirl.create(:publish_job, publish_method: Content::DEFAULT_PUBLISH_METHOD)
        allow_any_instance_of(Content).to receive(:publish_to_dsp).and_return(true)
        FactoryGirl.create_list(:content, 3)
        @job.before @job
        @job.perform

        @user = FactoryGirl.create(:admin)
        sign_in @user
      end

      it "should return a 404" do
        get :file_archive, { id: @job.id }
        expect(response.status).to be(404)
      end
    end
  end

end
