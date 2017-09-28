require 'rails_helper'

def parsed_results_count(response)
  JSON.parse(response.body)['contents'].length
end

RSpec.describe 'Organizations::Contents API Endpoints', type: :request do

  describe 'GET /api/v3/organizations/:organization_id/contents', elasticsearch: true do
    before do
      @talk_category = FactoryGirl.create :content_category, name: 'talk_of_the_town'
      @news_category = FactoryGirl.create :content_category, name: 'news'
      @campaign_category = FactoryGirl.create :content_category, name: 'campaign'
    end

    let(:user) { FactoryGirl.create :user }
    let(:auth_headers) { auth_headers_for(user) }

    context 'query' do
      let(:organization) { FactoryGirl.create :organization }
      let!(:content_not_matching) {
        FactoryGirl.create :content,
          :market_post,
          :published,
          title: 'Bambi',
          organization: organization
      }

      let!(:content_matching) {
        FactoryGirl.create :content,
          :market_post,
          :published,
          title: 'Cinderella',
          organization: organization
      }

      subject {
        get "/api/v3/organizations/#{organization.id}/contents", {query: 'Cinderella'}
      }

      it 'returns the content matching the query' do
        Timecop.travel(Time.current + 1.day) do
          subject
          expect(response_json[:contents].count).to eql 1
          expect(response_json[:contents][0][:id]).to eql content_matching.id
        end
      end
    end

    context "when no organization present" do
      subject do
        Timecop.travel(Time.current + 1.day)
        get '/api/v3/organizations/1/contents'
        Timecop.return
      end

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when organization present" do
      before do
        @organization = FactoryGirl.create :organization
      end

      subject do
        Timecop.travel(Time.current + 1.day)
        get "/api/v3/organizations/#{@organization.id}/contents"
        Timecop.return
      end

      context 'when Organization has BusinessLocation with Events' do
        before do
          business_location = FactoryGirl.create :business_location
          @organization.business_locations << business_location
          FactoryGirl.create :event, venue_id: business_location.id
        end

        it "returns Events" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization has tagged Content" do
        before do
          @organization.tagged_contents << FactoryGirl.create(:content)
        end

        it "returns tagged Content" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization owns Market Posts" do
        before do
          FactoryGirl.create :market_post, organization_id: @organization.id
        end

        it "returns the Market Posts" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization owns Events" do
        before do
          FactoryGirl.create :event, organization_id: @organization.id
        end

        it "returns the Events" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization owns Content in talk category" do
        before do
          FactoryGirl.create :content, :talk, organization_id: @organization.id
        end

        it "returns talk items" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization owns Content in news category" do
        before do
          FactoryGirl.create :content, :news, organization_id: @organization.id
        end

        it "returns news items" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Organization owns Content in campaign category" do
        before do
          content = FactoryGirl.create :content, :campaign, organization_id: @organization.id
        end

        it "returns campaign items" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end

      context "when Content is created but has no pubdate" do
        before do
          content = FactoryGirl.create :content,
            organization_id: @organization.id
          content.update_attribute(:pubdate, nil)
          @news_category.contents << content
        end

        it "does not return nil pubdate items" do
          subject
          expect(parsed_results_count(response)).to eq 0
        end
      end

      context "when Content is scheduled for future release" do
        before do
          content = FactoryGirl.create :content,
            organization_id: @organization.id,
            pubdate: Date.current + 5.days
          @news_category.contents << content
        end

        it "it does not return future pubdate items" do
          subject
          expect(parsed_results_count(response)).to eq 0
        end
      end

      context "when Content is campaign with no promotion" do
        before do
          @campaign = FactoryGirl.create :content, :campaign,
            organization_id: @organization.id
        end

        it "returns Content record" do
          subject
          expect(parsed_results_count(response)).to eq 1
        end
      end
    end
  end
end
