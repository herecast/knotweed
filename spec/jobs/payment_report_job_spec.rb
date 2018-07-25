require 'rails_helper'

RSpec.describe PaymentReportJob do
  describe 'with a valid report job', freeze_time: true do
    let!(:recipient1) { FactoryGirl.create :report_job_recipient, report_job: report_job }
    let!(:recipient2) { FactoryGirl.create :report_job_recipient, report_job: report_job }
    let(:content1) { FactoryGirl.create :content, created_by: recipient1.report_recipient.user }
    let(:content2) { FactoryGirl.create :content, created_by: recipient2.report_recipient.user }
    let(:report_job) { FactoryGirl.create :report_job }
    let(:payment_hash1) { {
      total_payment: rand(100),
      period_start: 1.week.ago,
      period_end: Date.today,
      payment_date: Time.current,
      pay_per_impression: rand(10),
      paid_impressions: rand(10),
      content_id: content1.id,
      paid_to: recipient1.report_recipient.user
    } }
    let(:payment_hash2) { {
      total_payment: rand(100),
      period_start: 1.week.ago,
      period_end: Date.today,
      payment_date: Time.current,
      pay_per_impression: rand(10),
      paid_impressions: rand(10),
      content_id: content2.id,
      paid_to: recipient2.report_recipient.user
    } }

    before do
      allow(PaymentReportService).to receive(:run_report).with(report_job.report.report_type, report_job.report_params_hash(recipient1)).
        and_return([payment_hash1])

      allow(PaymentReportService).to receive(:run_report).with(report_job.report.report_type, report_job.report_params_hash(recipient2)).
        and_return([payment_hash2])
    end

    subject { described_class.new.perform(report_job) }

    it 'should create a payment for reach recipient' do
      expect{subject}.to change{Payment.count}.by(2)
    end

    it 'should set the report_sent_date' do
      expect{subject}.to change{report_job.report_sent_date}.to Time.current
    end

    it 'should set the paid_to reference on the payments' do
      subject
      expect(Payment.where(content_id: content2.id).first.paid_to).to eq recipient2.report_recipient.user
    end

  end

end
