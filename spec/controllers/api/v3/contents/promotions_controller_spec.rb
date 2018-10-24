require 'spec_helper'

RSpec.describe Api::V3::Contents::PromotionsController, type: :controller do
  let(:user) { FactoryGirl.create :admin }
  before { api_authenticate user: user }

  describe "GET #index" do
    context "when content not found" do
      subject { get :index, params: { content_id: 1 } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when content present" do
      before do
        @content = FactoryGirl.create :content
      end

      subject { get :index, params: { content_id: @content.id } }

      context "when content has no promotions" do
        it "returns empty array" do
          subject
          promotions = JSON.parse(response.body)['promotions']
          expect(promotions).to eq []
        end
      end

      context "when content has promotions that are not shares" do
        let (:promotion) { FactoryGirl.create :promotion, content_id: @content.id }

        subject { get :index, params: { content_id: @content.id } }

        it "returns empty array" do
          subject
          promotions = JSON.parse(response.body)['promotions']
          expect(promotions).to eq []
        end
      end

      context 'as unauthorized user' do
        let(:user) { FactoryGirl.create :user }

        it 'returns forbidden status' do
          subject
          expect(response).to have_http_status :forbidden
        end
      end

      context "when content has promotions that are shares" do
        before do
          @promotion = FactoryGirl.create :promotion,
            content_id: @content.id,
            share_platform: 'Twitter'
        end

        subject { get :index, params: { content_id: @content.id } }

        it "returns empty array" do
          subject
          promotions = JSON.parse(response.body)['promotions']
          expect(promotions.length).to eq 1
        end
      end
    end
  end

  describe "POST #create" do
    context "when content is not present" do
      subject { post :create, params: { content_id: 1 } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "with improper params" do
      before do
        @content = FactoryGirl.create :content
        allow_any_instance_of(Promotion).to receive(:save).and_return false
      end

      subject { post :create, params: { content_id: @content.id, promotion: { pod: 'racer' } } }

      it "returns unprocessable_entity status" do
        subject
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "with proper params" do
      let (:content) { FactoryGirl.create :content }

      let (:params) {{
        content_id: content.id,
        promotion: {
          share_platform: 'Hothbook'
        }
      }}

      subject { post :create, params: params }

      it "creates a promotion" do
        expect{ subject }.to change{
          Promotion.count
        }.by 1
      end
    end
  end
end
