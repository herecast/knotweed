# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::Users::ConfirmationsController, type: :controller do

  describe 'POST create' do
    before do
      @user = FactoryGirl.create :user, confirmed_at: nil
      @subs = FactoryGirl.create_list :subscription, 2, user_id: @user.id, confirmed_at: nil, confirm_ip: nil
    end
    context 'with valid confirmation token' do
      # we have to call instance_variable_get to pull the raw token that's included in the email. confirmation_token in the DB is the encrypted version.
      subject! { post :create, params: { confirmation_token: @user.instance_variable_get(:@raw_confirmation_token) }, format: :json }

      it 'should respond with auth token' do
        expect(JSON.parse(response.body)).to eq({ token: @user.authentication_token,
                                                  email: @user.email }.stringify_keys)
      end

      it 'adds user to Mailchimp master list' do
        expectations = lambda do |job|
          job[:args][0] == 'Outreach::AddUserToMailchimpMasterList' &&
            job[:args][1] == 'call'
        end

        subject

        matching_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
          expectations[job]
        end
        expect(matching_jobs.length).to eq 1
      end

      context 'with unconfirmed digest subscriptions' do
        it 'confirms subscriptions after confriming their account' do
          expect(@subs.none? { |sub| sub.confirmed_at.nil? })
        end

        it 'calls the Mailchimp subscribe service' do
          expectations = lambda do |job|
            job[:args][0] == 'MailchimpService' &&
              job[:args][1] == 'subscribe'
          end

          subject

          matching_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
            expectations[job]
          end
          expect(matching_jobs.length).to eq @subs.count
        end
      end
    end

    context 'with invalid confirmation token' do
      subject! { post :create, params: { confirmation_token: 'fake' }, format: :json }

      it 'should respond with 404' do
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST update' do
    before do
      @user = FactoryGirl.create :user, confirmed_at: nil
    end

    context 'with a valid unconfirmed account' do
      subject { post :update, params: { user: { email: @user.email } } }

      it 'should trigger sending an email' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end

    context 'with an email not associated with any accounts' do
      subject! { post :update, params: { user: { email: 'does_not_exist@indatabase.com' } } }

      it 'should respond with 404 status' do
        expect(response.code).to eq('404')
      end
    end

    context 'with an already confirmed account' do
      before do
        @user.confirm
      end

      subject! { post :update, params: { user: { email: @user.email } } }

      it 'should respond with a message saying the user is already confirmed' do
        expect(response.body).to include('already confirmed')
      end
    end
  end
  
end
