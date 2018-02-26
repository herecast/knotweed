require 'rails_helper'

RSpec.describe ReportJobRecipient, type: :model do
  describe 'to_addresses' do
    let(:job_recipient) { FactoryGirl.create :report_job_recipient, report_recipient: report_recipient }
    let(:report_recipient) { FactoryGirl.create :report_recipient, alternative_emails: alt_emls }
    subject { job_recipient.to_addresses }

    context 'with no alternative_emails' do
      let(:alt_emls) { nil }
      
      it "should return the associated user's email" do
        expect(subject).to eq [job_recipient.report_recipient.user.email]
      end
    end
    
    context "with an alternative_email" do
      let(:alt_emls) { "alt_test@email.com" }
      
      it "should return the alternative email" do
        expect(subject).to eq [alt_emls]
      end
      
      describe "that contains multiple email addresses" do
        let(:alt_emls) { "alt_test@email.com,alt_2_test@email.com" }
        
        it "should return an array of the alternative emails split by comma" do
          expect(subject).to eq alt_emls.split(',')
        end
      end
    end
  end
end
