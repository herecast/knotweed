require 'spec_helper'

describe Api::V3::SubscriptionsController, type: :controller do
  describe 'POST update' do
    before do
      @user = FactoryGirl.create :user
      @listserv = FactoryGirl.create :listserv

      @sub_attrs = { subscription: {
        user_id: @user.id,
        listserv_id: @listserv.id,
        source: "daily_uv",
        email: @user.email,
        name: @user.name,
        confirmed_at: Time.zone.now,
        email_type: "html" }
      }
    end
    subject { post :create, @sub_attrs, format: :json }

    it 'responds successfully' do
      subject
      expect(response.code).to eq '201'
    end

    it 'creates a new subscription' do
      subject
      expect(assigns(:subscription)).to be_a Subscription
    end

    it 'sets confirmed_at and confirmation_ip' do
      subject
      expect(assigns(:subscription).confirmed_at).to_not be_nil
      expect(assigns(:subscription).confirm_ip).to_not be_nil
    end

    it 'silently subscribes a user to the listserv' do
      expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, '0.0.0.0')
      subject
    end

    it 'returns errors for invalid subscriptions' do
      @sub_attrs = { subscription: {
        user_id: @user.id,
        source: "daily_uv",
        email: @user.email,
        name: @user.name,
        confirmed_at: Time.zone.now,
        email_type: "html" }
      }

      post :create, @sub_attrs, format: :json
      expect(response.code).to eq '422'
    end
    
    it 'silently re-subscribes a user to the listserv' do
      expect(SubscribeToListservSilently).to receive(:call).with(@listserv, @user, '0.0.0.0')
      subject
    end

    context 'when a user re-subscribes' do
      
      it 'handles already persisted subscriptions' do
        @subscription = Subscription.create(@sub_attrs[:subscription])
        subject
        expect(response.code).to eq '201'
      end

      it 'resubscribes existing subscriptions' do
        @subscription = Subscription.create(@sub_attrs[:subscription].merge(unsubscribed_at: Time.zone.now))
        subject
        expect(assigns(:subscription).unsubscribed_at).to be_nil
      end
      
    end
  end

  describe 'POST /api/v3/unsubscribe_from_mailchimp' do
    let(:user) { FactoryGirl.create :user }
    let(:listserv) { FactoryGirl.create :listserv, mc_list_id: '58b689ef45', mc_group_name: 'Test Digest' }
    let!(:subscription) { FactoryGirl.create :subscription, email: user.email, listserv_id: listserv.id }
    let(:mc_request) { {"type"=>"unsubscribe", 
                        "fired_at"=>"2016-09-21 15:32:52", 
                        "data"=>{"action"=>"unsub", 
                                 "reason"=>"manual", 
                                 "id"=>"ecdecee112", 
                                 "email"=>"#{user.email}", 
                                 "email_type"=>"html", 
                                 "ip_opt"=>"68.81.4.98", 
                                 "web_id"=>"134812609", "merges"=>{"EMAIL"=>"test@subtext.org", 
                                                                   "FNAME"=>"Testy", 
                                                                    "LNAME"=>"McTesterson"}, 
                                 "list_id"=>"#{listserv.mc_list_id}"}} }

    subject { post :unsubscribe_from_mailchimp, mc_request }
 
    #maybe set up VCR to get the response or create a fixture
    context 'when the user unsubscribes' do
      it 'has a 200 status code' do
        subject
        expect(response.code).to eq('200')
      end
      
      it 'updates the subscription' do
        subject
        body = JSON.parse(response.body)
        expect(body['subscription']['unsubscribed_at']).to_not be_nil
      end
    end

    context 'when the user is unsubscribed' do
      before do
        subscription.update_attributes(unsubscribed_at: 1.day.ago)
      
      end
      it 'has a 200 status code' do
        subject
        expect(response.code).to eq('200')
      end
      
      it 'does not change subscribed_at if already set' do
        expect { subject }.not_to change { subscription.unsubscribed_at }
      end
    end

  end
end
