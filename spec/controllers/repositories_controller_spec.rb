require 'spec_helper'

describe RepositoriesController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    before do
      @repos = FactoryGirl.create_list :repository, 3
    end

    subject! { get :index }

    it 'should respond with a 200 code' do
      expect(response.code).to eq '200'
    end

    it 'should load the repositories' do
      expect(assigns(:repositories)).to eq @repos
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with a 200 code' do
      expect(response.code).to eq '200'
    end
  end


  describe 'GET edit' do
    before { @repo = FactoryGirl.create :repository }
    subject! { get :edit, id: @repo.id }

    it 'should respond with a 200 code' do
      expect(response.code).to eq '200'
    end

    it 'should load the repository' do
      expect(assigns(:repository)).to eq @repo
    end
  end

  describe 'GET clear_published_contents' do
    before do
      contents = FactoryGirl.create_list :content, 3
      @repo = FactoryGirl.create :repository, contents: contents
    end

    subject { get :clear_published_contents, id: @repo.id }

    it 'should clear the repositories contents' do
      expect{subject}.to change{@repo.contents.count}.to 0
    end
  end

  describe 'POST create' do
    before do
      @repo_params = { name: 'Repository', dsp_endpoint: 'http://www.google.com',
                       sesame_endpoint: 'http://www.google.com' }
    end

    subject { post :create, repository: @repo_params }

    it 'should create a repository' do
      expect{subject}.to change{Repository.count}.by 1
    end
  end

  describe 'PUT update' do
    before do
      @repo = FactoryGirl.create :repository
      @update_params = { name: 'Fake Changed Repo Name' }
    end

    subject { put :update, repository: @update_params, id: @repo.id }

    it 'should update the repository' do
      expect{subject}.to change{@repo.reload.name}.to @update_params[:name]
    end
  end

end
