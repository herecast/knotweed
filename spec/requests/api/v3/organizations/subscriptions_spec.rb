# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Organization Subscriptions Endpoints', type: :request do
  let(:caster) { FactoryGirl.create :caster }
  let(:organization) { FactoryGirl.create :organization, user_id: caster.id }
  let(:user) { FactoryGirl.create :user }
  let(:headers) { auth_headers_for(user) }

  describe 'GET /api/v3/organizations/subscriptions', elasticsearch: true do
    before do
      @query = 'Han'
      @publisher = FactoryGirl.create :organization,
                                      org_type: 'Publisher',
                                      name: "#{@query} 1"
      @valid_business = FactoryGirl.create :organization,
                                           org_type: 'Business',
                                           biz_feed_active: true,
                                           name: "#{@query} 2"
      @invalid_business = FactoryGirl.create :organization,
                                             org_type: 'Business',
                                             biz_feed_active: false,
                                             name: "#{@query} 3"
    end

    subject { get "/api/v3/organizations/subscriptions?query=#{@query}" }

    it 'returns publishers and valid businesses' do
      subject
      returned_org_ids = JSON.parse(response.body)['organizations'].map { |org| org['id'] }
      expect(returned_org_ids).to match_array [@publisher.id, @valid_business.id]
      expect(returned_org_ids).not_to include @invalid_business.id
    end
  end

  describe 'POST /api/v3/organizations/:organization_id/subscriptions' do
    before do
      allow(Outreach::CreateOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).and_return true
    end

    subject do
      post "/api/v3/organizations/#{organization.id}/subscriptions",
           headers: headers
    end

    it 'creates OrganizationSubscription' do
      expect { subject }.to change {
        OrganizationSubscription.count
      }.by 1
    end

    it 'calls to create subscription in Mailchimp' do
      expect(Outreach::CreateOrganizationSubscriptionInMailchimp).to receive(
        :call
      )
      subject
    end
  end

  describe 'DELETE /api/v3/organizations/subscriptions/:id' do
    before do
      @org_subscription = FactoryGirl.create :organization_subscription,
                                             user_id: user.id,
                                             organization_id: organization.id
      allow(Outreach::DestroyOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).and_return true
    end

    subject do
      delete "/api/v3/organizations/subscriptions/#{@org_subscription.id}",
             headers: headers
    end

    it 'calls to destroy subscription in Mailchimp' do
      expect(Outreach::DestroyOrganizationSubscriptionInMailchimp).to receive(
        :call
      ).with(@org_subscription)
      subject
    end
  end
end
