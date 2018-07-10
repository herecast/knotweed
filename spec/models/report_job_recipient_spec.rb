# == Schema Information
#
# Table name: report_job_recipients
#
#  id                     :integer          not null, primary key
#  report_job_id          :integer
#  report_recipient_id    :integer
#  created_by             :integer
#  updated_by             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  report_review_date     :datetime
#  report_sent_date       :datetime
#  jasper_review_response :text
#  jasper_sent_response   :text
#  run_failed             :boolean          default(FALSE)
#

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
