require 'spec_helper'

describe ReportJobRecipientsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  let!(:report_job_recipient) { FactoryGirl.create :report_job_recipient }
  before { sign_in admin }
    
  describe 'GET edit' do
    subject! { get :edit, id: report_job_recipient.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the report_job_recipient' do
      expect(assigns(:report_job_recipient)).to eq report_job_recipient
    end
  end

  describe 'PUT update' do
    let(:update_params) { { report_job_params_attributes: [{ param_name: 'test_new_param', param_value: '12345' }] } }
    subject { put :update, id: report_job_recipient.id, report_job_recipient: update_params, format: :js }

    it 'should create a new report_job_param' do
      expect{subject}.to change{ReportJobParam.count}.by 1
    end
  end

  describe 'DELETE destroy' do
    subject { delete :destroy, id: report_job_recipient.id, format: :js }

    it 'should destroy the report job recipient' do
      expect{subject}.to change{ReportJobRecipient.count}.by -1
    end
  end
end
