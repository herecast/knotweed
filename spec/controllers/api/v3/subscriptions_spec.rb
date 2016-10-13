require 'spec_helper'

describe Api::V3::SubscriptionsController, type: :controller do

  describe 'POST /api/v3/unsubscribe_from_mailchimp' do
    let(:user) { FactoryGirl.create :user }
    let(:listserv) { FactoryGirl.create :listserv, mc_list_id: '58b689ef45' }
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
