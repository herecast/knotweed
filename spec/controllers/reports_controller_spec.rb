require 'spec_helper'

describe ReportsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    let!(:reports) { FactoryGirl.create_list :report, 2 }
    subject! { get :index }
    
    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the reports' do
      expect(assigns(:reports)).to eq reports
    end
  end

  describe 'GET edit' do
    let!(:report) { FactoryGirl.create :report }
    subject! { get :edit, id: report.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the report' do
      expect(assigns(:report)).to eq report
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'POST create' do
    subject { post :create, report: { title: 'Test Title',
                                      report_type: PaymentReportService::AVAILABLE_REPORTS[0] } }

    it 'should create a report' do
      expect{subject}.to change{Report.count}.by 1
    end

    describe 'when creation fails' do
      it 'renders new page' do
        allow_any_instance_of(Report).to receive(:save).and_return false
        subject
        expect(response).to render_template 'new'
      end
    end
  end

  describe 'PUT update' do
    let!(:report) { FactoryGirl.create :report }
    let(:update_params) { { title: "New Title" } }

    subject { put :update, id: report.id, report: update_params }

    it 'should update the report' do
      expect{subject}.to change{report.reload.title}.to update_params[:title]
    end

    describe 'when update fails' do
      it 'renders edit page' do
        allow_any_instance_of(Report).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

end
