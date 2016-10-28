require 'spec_helper'

describe ParsersController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "GET #parameters" do
    let!(:parser) { FactoryGirl.create :parser }
    let!(:import_job) { FactoryGirl.create :import_job }
    let!(:parameter) { FactoryGirl.create :parameter, parser_id: parser.id }

    subject { get :parameters, id: parser.id, import_job_id: import_job.id }

    it "runs" do
      subject
      expect(response).to have_http_status :success
    end
  end

  describe 'GET index' do
    before { @parsers = FactoryGirl.create_list :parser, 3 }
    subject! { get :index }

    it 'should respond with 200 status code' do
      expect(response.code).to eq '200'
    end

    it 'should load the parsers' do
      expect(assigns(:parsers)).to eq @parsers
    end
  end

  describe 'GET edit' do
    before { @parser = FactoryGirl.create :parser }
    subject! { get :edit, id: @parser.id }

    it 'should respond with 200 status code' do
      expect(response.code).to eq '200'
    end

    it 'should load the parser' do
      expect(assigns(:parser)).to eq @parser
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with 200 status code' do
      expect(response.code).to eq '200'
    end
  end

  describe 'POST create' do
    subject { post :create, parser: { name: 'Fake Parser', filename: 'fake_parser.rb' } }

    context "when creation succeeds" do
      it 'should create a new parser' do
        expect{subject}.to change{Parser.count}.by 1
      end
    end

    context "when creation fails" do
      it "should not create a new parser" do
        allow_any_instance_of(Parser).to receive(:save).and_return(false)
        expect{ subject }.to change{ Parser.count }.by(0)
      end
    end
  end

  describe 'PUT update' do
    before do
      @parser = FactoryGirl.create :parser
      @update_params = { name: 'New Updated Name' }
    end

    subject { put :update, id: @parser.id, parser: @update_params }

    it 'should update the parser record' do
      expect{subject}.to change{@parser.reload.name}.to @update_params[:name]
    end
  end

  describe 'DELETE #destroy' do
    let!(:parser) { FactoryGirl.create :parser }

    subject { delete :destroy, id: parser.id, format: :js }

    it "should delete parser" do
      expect{ subject }.to change{ Parser.count }.by(-1)
    end
  end
end
