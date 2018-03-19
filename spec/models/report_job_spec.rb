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
        alert_recipients: report_job.emails_for(:alert_recipients),
        cc_emails: report_job.emails_for(:cc_emails),
        bcc_emails: report_job.emails_for(:bcc_emails)
      }
    end

    let(:response) { double("response", code: 200, body: 'success') }

    # don't actually run the job
    before do
      allow(JasperService).to receive(:submit_job).with(any_args).and_return(response)
    end

    subject { report_job.run_report_job(is_review) }

    describe 'when the API call fails' do
      let(:response) { double("response", code: 400, body: 'FAILURE :(') }
      let(:is_review) { true }

      it 'should set run_failed to true on the recipient' do
        expect{subject}.to change{recipient1.reload.run_failed}.to true
      end

      it 'should store the api response body on the recipient' do
        expect{subject}.to change{recipient1.reload.jasper_review_response}.to response.body
      end

      it 'should return the correct results' do
        expect(subject).to eq({ successes: 0, failures: 1 })
      end
    end

    context 'as a review' do
      let(:is_review) { true }
      
      it 'should call JasperService.submit_job with the correct args' do
        expect(JasperService).to receive(:submit_job).with(args)
        subject
      end

      it 'should set report_review_date' do
        expect{subject}.to change{report_job.report_review_date}.to Time.zone.now
      end

      it 'should set report_review_date on the recipient' do
        expect{subject}.to change{recipient1.reload.report_review_date}.to Time.zone.now
      end

      it 'should ensure run_failed is false on the recipient' do
        subject
        expect(recipient1.reload.run_failed).to be false
      end

      it 'should populate the jasper_review_response column on the recipient' do
        expect{subject}.to change{recipient1.reload.jasper_review_response}.to response.body
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

      it 'should return the correct results' do
        expect(subject).to eq({ successes: 2, failures: 0 })
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

      it 'should set report_sent_date on the recipient' do
        expect{subject}.to change{recipient1.reload.report_sent_date}.to Time.zone.now
      end

      it 'should ensure run_failed is false on the recipient' do
        subject
        expect(recipient1.reload.run_failed).to be false
      end

      it 'should populate the jasper_sent_response column on the recipient' do
        expect{subject}.to change{recipient1.reload.jasper_sent_response}.to response.body
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

  describe 'emails_for(reports_field)' do
    let!(:report_job) { FactoryGirl.create :report_job }
    let(:reports_field) { :alert_recipients }
    
    subject { report_job.emails_for(reports_field) }

    context 'with an invalid reports_field' do
      let(:reports_field) { :fake_field }

      it 'should return an empty array' do
        expect(subject).to eq []
      end
    end

    context 'with a single email address' do
      let(:email) { "test@email.com" }
      before { allow(report_job.report).to receive(reports_field).and_return(email) }

      it 'should return an array containing that email' do
        expect(subject).to eq [email]
      end
    end

    context 'with multiple email addresses' do
      let(:emails) { "test@email.com, other_email@fake.com" }
      before { allow(report_job.report).to receive(reports_field).and_return(emails) }

      it 'should return an array containing that email' do
        expect(subject).to match_array(emails.split(",").map(&:strip))
      end
    end
  end
end
