require 'spec_helper'

describe Reports::GenerationsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }
  describe 'POST create' do
    let!(:report) { FactoryGirl.create :report }
    subject { get :create, report_id: report.id }

    it 'creates a report job' do
      expect{subject}.to change{ReportJob.count}.by 1
    end

    it 'should redirect to the report job' do
      subject
      expect(response).to redirect_to edit_report_job_path(ReportJob.last)
    end
  end
end
