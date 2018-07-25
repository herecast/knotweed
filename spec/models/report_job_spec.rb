# == Schema Information
#
# Table name: report_jobs
#
#  id                 :integer          not null, primary key
#  report_id          :integer
#  description        :text
#  report_review_date :datetime
#  report_sent_date   :datetime
#  created_by         :integer
#  updated_by         :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'rails_helper'

RSpec.describe ReportJob, type: :model do
  describe 'report_params_hash' do
    let(:report_job) { FactoryGirl.create :report_job }
    let(:report_job_recipient) { FactoryGirl.create :report_job_recipient, report_job: report_job }
    let!(:rp1) { FactoryGirl.create :report_job_param, report_job_paramable: report_job }
    subject { report_job.report_params_hash(report_job_recipient) }

    it 'should return the report job parameters as a key/value hash' do
      expect(subject).to include({ rp1.param_name.to_sym => rp1.param_value })
    end

    it 'should include the corresponding user ID' do
      expect(subject).to include({ :user_id => report_job_recipient.report_recipient.user.id })
    end
    
    context 'with report_job_recipient params' do
      let!(:rjp1) { FactoryGirl.create :report_job_param, report_job_paramable: report_job_recipient }
      
      it 'should return the report job recipient parameter in the key/value hash' do
        expect(subject).to include({ rjp1.param_name.to_sym => rjp1.param_value })
      end
    end
  end

  describe 'self.create_from_report!' do
    let(:report) { FactoryGirl.create :report }
    let!(:report_param) { FactoryGirl.create :report_param, report: report,
      report_param_type: :report }
    let!(:recipient_param) { FactoryGirl.create :report_param, report: report,
      report_param_type: :recipient }
    let!(:rr1) { FactoryGirl.create :report_recipient, report: report }
    let!(:archived_rr) { FactoryGirl.create :report_recipient, report: report, archived: true }

    subject { ReportJob.create_from_report!(report) }

    it 'should return a report job' do
      expect(subject).to be_instance_of(ReportJob)
    end

    it 'should create report_job_params for each report type param' do
      expect{subject}.to change{ReportJobParam.where(report_job_paramable_type: 'ReportJob').count}.by(1)
    end

    it 'should create report_job_recipients for each active report_recipient' do
      expect(subject.report_job_recipients.count).to eq report.report_recipients.active.count
    end

    it 'should not create a report_job_recipient for archived report_recipient' do
      users = subject.report_job_recipients.map{ |rjr| rjr.report_recipient.user }
      expect(users).to_not include(archived_rr.user)
    end

    it "should create report_job_params for each recipient type param" do
      expect{subject}.to change{ReportJobParam.where(report_job_paramable_type: 'ReportJobRecipient').count}.by(1)
    end
  end
end
