require 'spec_helper'

describe SubtextTracker do
  let(:token) { 'D@-TOK3N' }
  subject { described_class.new(token) }

  describe '#track' do
    pending "This method is not currently testable with alias_method"
=begin
    context 'Given a user argument' do
      let(:user) { FactoryGirl.create :user }

      it 'sets up user properties for tracking' do
        distinct_id = 'did'
        event = "track this"
        expect_any_instance_of(Mixpanel::Events).to receive(:track).with(distinct_id, event, hash_including({
          'userId' => user.id,
          'userName' => user.name,
          'userEmail' => user.email,
          'userCommunity' => user.location.name,
          'testGroup' => user.test_group
        }))

        subject.track(distinct_id, event, user)
      end
    end
=end
  end

  describe "#navigation_properties" do
    it 'returns properties as hash' do
      channelName = 'test channel'
      pageName = 'the page'
      url = 'http://the.url'
      pageNumber = 1

      expected_response = {channelName: channelName, pageName: pageName, url: url, pageNumber: pageNumber}.with_indifferent_access

      expect( subject.navigation_properties(channelName, pageName, url, page: pageNumber) ).to eql expected_response
    end
  end

  describe '#search_properties' do
    it 'returns correct matching properties' do
      params = {
        category: 'the category',
        start_date: 'the start date',
        end_date: 'the end date',
        query: 'the query',
        publication: 'the publication',
        location: 'my location'
      }

      expect( subject.search_properties(params) ).to include({
        'category' => params[:category],
        'searchStartDate' => params[:start_date],
        'searchEndDate' => params[:end_date],
        'query' => params[:query],
        'publication' => params[:publication],
        'location' => params[:location]
      })
    end

    context 'location not included in params' do
      it 'returns location: All Communities' do
        expect( subject.search_properties({}) ).to include('location' => 'All Communities')
      end
    end
  end

  describe '#content_properties' do
    context 'given a content record' do
      let(:content) { FactoryGirl.create :content }
      it 'returns a hash with matching properties' do
        return_val = subject.content_properties(content)
        expect( return_val ).to include({
          'contentId' => content.id,
          'contentChannel' => content.channel_type,
          'contentLocation' => content.location,
          'contentPubdate' => content.pubdate,
          'contentTitle' => content.title
        })
      end
    end
  end

  describe '#banner_properties' do
    context 'given a banner record' do
      let(:banner){ FactoryGirl.create :promotion_banner }
      it 'returns a hash with matching properties' do
        return_val = subject.banner_properties(banner)
        expect(return_val).to include({
          'bannerAdId' => banner.id,
          'bannerUrl' => banner.redirect_url
        })
      end
    end
  end

  describe '#content_creation_properties' do
    it 'converts arguments into a hash' do
      submitType = 'the type'
      inReplyTo = 'reply to me'
      expect( subject.content_creation_properties(submitType, inReplyTo) ).to include({
        'submitType' => submitType,
        'inReplyTo' => inReplyTo
      })
    end
  end
end
