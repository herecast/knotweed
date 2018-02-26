require 'spec_helper'

describe ReportJobsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    subject! { get :index }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    context 'Given a search query' do
      let!(:report_job1) { FactoryGirl.create :report_job }
      let!(:report_job2) { FactoryGirl.create :report_job }
      subject { get :index, q: { "report_id_eq" => report_job1.report.id } }

      it 'should return the correct reports' do
        subject
        expect(assigns(:report_jobs)).to eq [report_job1]
      end
    end
  end

  describe 'GET edit' do
    let!(:report_job) { FactoryGirl.create :report_job }
    subject! { get :edit, id: report_job.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the report_job' do
      expect(assigns(:report_job)).to eq report_job
    end
  end

  describe 'PUT update' do
    let!(:report_job) { FactoryGirl.create :report_job }
    let(:update_params) { { description: "New description" } }

    subject { put :update, id: report_job.id, report_job: update_params }

    it 'should update the report' do
      expect{subject}.to change{report_job.reload.description}.to update_params[:description]
    end

    describe 'when update fails' do
      it 'renders edit page' do
        allow_any_instance_of(ReportJob).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

  describe 'POST create' do
    let!(:report) { FactoryGirl.create :report }

    subject { post :create, report_job: { report_id: report.id, description: 'test' } }

    it 'should create a report job' do
      expect{subject}.to change{ReportJob.count}.by 1
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end
end
