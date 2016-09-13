require 'rails_helper'

describe 'Post To Listserv Workflows', type: :request do
  it "New Post not enhance; New Post enhance; Updated subscription#user_id" do
    listserv = FactoryGirl.create(:listserv)
    post1 = FactoryGirl.create(:listserv_content, 
      listserv: listserv,
      subscription: nil,
      user: nil,
      verified_at: nil)

    # Confirm/Verify only.  No enhance
    put "/api/v3/listserv_contents/#{post1.key}", listserv_content: {id: post1.key}
    post1_json = response_json.dup
    expect(post1_json[:listserv_content][:user_id]).to be nil

    #creates subscription
    subscription_id = response_json[:listserv_content][:subscription_id]
    get "/api/v3/subscriptions/#{subscription_id}"
    subscription_json = response_json.dup
    expect(subscription_json[:subscription][:email]).to eql(post1_json[:listserv_content][:sender_email])

    # Post, enhance
    post2 = FactoryGirl.create(:listserv_content,
      listserv: listserv,
      subscription: nil,
      user: nil,
      sender_email: post1.sender_email,
      verified_at: nil)
    user = FactoryGirl.create(:user, email: post1.sender_email)
    content = FactoryGirl.create(:content, created_by: user)
    put "/api/v3/listserv_contents/#{post2.key}", {
      listserv_content: {
        content_id: content.id
      }
    }
    post2_json = response_json.dup
    expect(post2_json[:listserv_content][:user_id].to_s).to eql user.id.to_s

    expect(post2_json[:listserv_content][:subscription_id]).to eql subscription_id

    # Ensure user reference is updated
    get "/api/v3/subscriptions/#{subscription_id}"
    subscription_json = response_json.dup
    expect(subscription_json[:subscription][:user_id].to_s).to eql user.id.to_s
  end
end
