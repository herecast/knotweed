require 'spec_helper'

describe PublishJobsController do 

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
          source_id: ["3"], import_location_id: ["4"],
          from: nil, to: nil, published: nil,
          ids: nil,
          repository_id: nil
        }
        post_params = @query_hash.merge({ publish_job: @publish_job_hash })
        post :create, post_params
        @job = PublishJob.first
      end

      it "should redirect to publish jobs path" do
        response.should redirect_to(publish_jobs_path)
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

  describe "GET 'file_archive'" do
    context "with a completed job with a file_archive" do
      before do
        @job = FactoryGirl.create(:publish_job, publish_method: Content::EXPORT_TO_XML)
        FactoryGirl.create_list(:content, 3)
        @job.before @job
        @job.perform
      end

      after do
        system("rm -rf #{Figaro.env.content_export_path}/*")
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
        @job = FactoryGirl.create(:publish_job, publish_method: Content::POST_TO_ONTOTEXT)
        Content.any_instance.stub(:post_to_ontotext).and_return(true)
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
