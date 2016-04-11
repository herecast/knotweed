require 'spec_helper'

describe PublishJobsController, type: :controller do

  it_behaves_like 'JobController'

  describe 'GET #contents_count' do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
    end

    it 'sets @count to the count of contents matching optional query' do
      fake = double(count: 100)
      expect(Content).to receive(:contents_query).and_return(fake)

      get :contents_count
      expect(assigns(:count)).to eql 100
    end
  end

  describe 'GET #job_contents_count' do
    let(:record) { FactoryGirl.build_stubbed :publish_job }

    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user

      allow(PublishJob).to receive(:find).and_return(record)
    end

    it 'assigns @publish_job for view' do
      get :job_contents_count, id: record.id
      expect(assigns(:publish_job)).to eql record
    end
  end

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
        response.should redirect_to(publish_jobs_path)
      end

      it "should properly serialize query params" do
        @job.should_not be_nil
        @job.query_params.should== @query_hash
      end

      it "should register current user as a notifyee of the job" do
        @job.notifyees.include?(@user).should== true
      end

      context 'invalid attributes' do
        before do
          allow_any_instance_of(PublishJob).to receive(:update_attributes).and_return(false)
        end

        it 're renders "new" template' do
          post :create, {publish_job: {invalid: 'data'}}
          expect(response).to render_template('publish_jobs/new')
        end
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
      response.code.should eq '200'
    end

    it 'should load the publish jobs' do
      assigns(:publish_jobs).should eq @jobs
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
      response.code.should eq '200'
    end

    it 'should load the publish job' do
      assigns(:publish_job).should eq @job
    end
  end

  describe 'PUT #update', focus: true do
    let(:record) { FactoryGirl.create :publish_job }

    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user

      allow(PublishJob).to receive(:find).and_return(record)
    end

    context 'with valid params' do
      let(:query_params) { {repository_id: 1} }
      let(:valid_params) { {name: 'A Valid Name', query_params: true} }

      it 'fetches the query params and sets them on the model' do
        put :update, query_params.merge(id: record.id, publish_job: valid_params)
        expect(record.query_params.with_indifferent_access[:repository_id]).to eql "1"
      end

      it 'updates the record' do
        put :update, query_params.merge(id: record.id, publish_job: valid_params)
        expect(record.name).to eql 'A Valid Name'
      end

      it 'redirects to publush_jobs_path' do
        put :update, query_params.merge(id: record.id, publish_job: valid_params)
        expect(response).to redirect_to(publish_jobs_path)
      end
    end

    context 'with invalid params' do
      let(:query_params) { {repository_id: 1} }
      let(:invalid_params) { {invalid: 'A Valid Name', query_params: true} }

      before do
        allow(record).to receive(:save).and_return(false)
        allow(record).to receive(:update_attributes).and_return(false)
      end

      it 're renders "edit" template' do
        put :update, query_params.merge(id: record.id, publish_job: invalid_params)
        expect(response).to render_template('publish_jobs/edit')
      end
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
        Content.any_instance.stub(:publish_to_dsp).and_return(true)
        FactoryGirl.create_list(:content, 3)
        @job.before @job
        @job.perform

        @user = FactoryGirl.create(:admin)
        sign_in @user
      end

      # monkey patch suggested here: https://github.com/rspec/rspec-rails/issues/1532
      # this is the only place we use `render :file` which was broken for rspec by 
      # Rails 3.2.22, so I'm just stuffing this in here til we upgrade.
      RSpec::Rails::ViewRendering::EmptyTemplatePathSetDecorator.class_eval do  
        alias_method :find_all_anywhere, :find_all
      end

      it "should return a 404" do
        get :file_archive, { id: @job.id }
        expect(response.status).to be(404)
      end
    end
  end

end
