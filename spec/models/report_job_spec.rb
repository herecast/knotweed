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
      expect(subject).to include({ rp1.param_name => rp1.param_value })
    end

    it 'should include the corresponding user ID' do
      expect(subject).to include({ "user_id" => report_job_recipient.report_recipient.user.id })
    end
    
    context 'with report_job_recipient params' do
      let!(:rjp1) { FactoryGirl.create :report_job_param, report_job_paramable: report_job_recipient }
      
      it 'should return the report job recipient parameter in the key/value hash' do
        expect(subject).to include({ rjp1.param_name => rjp1.param_value })
      end
    end
  end

  describe 'run_report_job', freeze_time: true do
    let(:report_job) { FactoryGirl.create :report_job }
    let!(:recipient1) { FactoryGirl.create :report_job_recipient, report_job: report_job }
    let(:is_review) { true }
    
    let(:args) do
      {
        output_file_name: report_job.filename(recipient1),
        run_type: is_review ? :review : :send,
        review_folder: report_job.report.repository_folder,
        overwrite: report_job.report.overwrite_files,
        report_params: report_job.report_params_hash(recipient1),
        recipients: [recipient1.report_recipient.user.email],
        report_path: report_job.report.report_path,
        email_subject: report_job.report.email_subject,
        output_formats: is_review ? report_job.report.output_formats_review : report_job.report.output_formats_send,
        alert_recipients: report_job.report.alert_recipients,
        cc_email: report_job.report.cc_email,
        bcc_email: report_job.report.bcc_email
      }
    end

    # don't actually run the job
    before do
      allow(JasperService).to receive(:submit_job).with(any_args).and_return(true)
    end

    subject { report_job.run_report_job(is_review) }

    context 'as a review' do
      let(:is_review) { true }
      
      it 'should call JasperService.submit_job with the correct args' do
        expect(JasperService).to receive(:submit_job).with(args)
        subject
      end

      it 'should set report_review_date' do
        expect{subject}.to change{report_job.report_review_date}.to Time.zone.now
      end
    end
    
    context 'with multiple recipients' do
      let!(:recipient2) { FactoryGirl.create :report_job_recipient, report_job: report_job }
      
      it 'should call JasperService.submit_job twice' do
        expect(JasperService).to receive(:submit_job).with(any_args).twice
        subject
      end
      
      it "should call JasperService.submit_job with recipient2's email address" do
        expect(JasperService).to receive(:submit_job).with(args.merge(
          {recipients: [recipient2.report_recipient.user.email], report_params: report_job.report_params_hash(recipient2)}
        ))
        subject
      end
      
      it "should call JasperService.submit_job with recipient1's email address" do
        expect(JasperService).to receive(:submit_job).with(args.merge(
          {recipients: [recipient1.report_recipient.user.email], report_params: report_job.report_params_hash(recipient1)}
        ))
        subject
      end
    end

    context 'as a send report' do
      let(:is_review) { false }

      it 'should call JasperService.submit_job with the correct args' do
        expect(JasperService).to receive(:submit_job).with(args)
        subject
      end

      it 'should set report_sent_date' do
        expect{subject}.to change{report_job.report_sent_date}.to Time.zone.now
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

    subject { ReportJob.create_from_report!(report) }

    it 'should return a report job' do
      expect(subject).to be_instance_of(ReportJob)
    end

    it 'should create report_job_params for each report type param' do
      expect{subject}.to change{ReportJobParam.where(report_job_paramable_type: 'ReportJob').count}.by(1)
    end

    it 'should create report_job_recipients for each report_recipient' do
      expect(subject.report_job_recipients.count).to eq report.report_recipients.count
    end

    it "should create report_job_params for each recipient type param" do
      expect{subject}.to change{ReportJobParam.where(report_job_paramable_type: 'ReportJobRecipient').count}.by(1)
    end
  end
end
