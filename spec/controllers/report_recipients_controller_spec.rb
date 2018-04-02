require 'rails_helper'

RSpec.describe ReportRecipientsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  let(:report) { FactoryGirl.create :report }

  describe 'GET new' do
    let(:user) { FactoryGirl.create :user }
    subject! { get :new, report_id: report.id, user_id: user.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'POST create' do
    context 'with an existing but archived report_recipient' do
      let(:rr) { FactoryGirl.create :report_recipient, report: report, archived: true }
      let(:create_params) { { report_id: report.id, user_id: rr.user_id } }

      subject { post :create, report_recipient: create_params, format: :js }

      it 'should update archived to false on the report_recipient' do
        expect{subject}.to change{rr.reload.archived}.to false
      end

      context 'with a changed alternative_emails' do
        subject { post :create, report_recipient: create_params.merge({ alternative_emails: 'fake_alt_emails@email.com' }),
                    format: :js }

        it 'should update the alternative_emails on the report_recipient' do
          expect{subject}.to change{rr.reload.alternative_emails}.to 'fake_alt_emails@email.com'
        end
      end
    end

    context 'with no existing report_recipient record' do
      let(:user) { FactoryGirl.create :user }
      subject { post :create, report_recipient: { user_id: user.id, report_id: report.id },
                  format: :js }

      it 'should create a report_recipient record' do
        expect{subject}.to change{ReportRecipient.count}.by 1
      end
    end
  end

  describe 'DELETE destroy' do
    let(:rr) { FactoryGirl.create :report_recipient, report: report, archived: false }
    subject { delete :destroy, id: rr.id, format: :js }

    it 'should archive the report_recipient' do
      expect{subject}.to change{rr.reload.archived}.to true
    end
  end
end
