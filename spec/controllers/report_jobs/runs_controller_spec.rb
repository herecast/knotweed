require 'spec_helper'

describe ReportJobs::RunsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }
  describe 'POST create' do
    let!(:report_job) { FactoryGirl.create :report_job }
    let(:review_type) { "review" }
    subject { post :create, report_job_id: report_job.id, review_type: review_type }

    it 'should call run_report_job with the correct argument' do
      allow(ReportJob).to receive(:find).and_return(report_job) # needs to be exact same object for spec
      expect(report_job).to receive(:run_report_job).with(true)
      subject
    end
  end
  
end
