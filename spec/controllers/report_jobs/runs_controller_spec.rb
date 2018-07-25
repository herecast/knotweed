require 'spec_helper'

describe ReportJobs::RunsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }
  describe 'POST create' do
    let!(:report_job) { FactoryGirl.create :report_job }
    subject { post :create, report_job_id: report_job.id }

    it 'should queue a PaymentReportJob' do
      expect{subject}.to enqueue_job(PaymentReportJob).with(report_job)
    end
  end
  
end
