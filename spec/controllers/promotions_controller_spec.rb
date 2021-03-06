# frozen_string_literal: true

require 'spec_helper'

describe PromotionsController, type: :controller do
  # include Devise::TestHelpers

  before do
    user = FactoryGirl.create(:admin)
    sign_in user
    @org = FactoryGirl.create(:organization)
    @content = FactoryGirl.create(:content)
    @promotion = FactoryGirl.create(:promotion, organization: @org, content: @content)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  describe 'GET index' do
    subject { get :index, params: { organization_id: @org } }
    it 'assigns all promotions as @promotions' do
      subject
      expect(assigns(:promotions)).to eq([@promotion])
    end
  end

  describe 'GET show' do
    subject { get :show, params: { id: @promotion.to_param } }
    it 'assigns the requested promotion as @promotion' do
      subject
      expect(assigns(:promotion)).to eq(@promotion)
    end
  end

  describe 'GET edit' do
    subject { get :edit, params: { id: @promotion.to_param } }
    it 'assigns the requested promotion as @promotion' do
      subject
      expect(assigns(:promotion)).to eq(@promotion)
    end
  end

  describe 'POST create' do
    let(:content) { FactoryGirl.create :content }
    let(:options) { { description: 'Another great promotion!', content_id: content.id } }

    before { allow(SubtextAdService).to receive(:add_creative).with(any_args).and_return(true) }

    subject { post :create, params: { promotion: options, organization_id: @org } }

    describe 'with valid params' do
      it 'creates a new Promotion' do
        expect { subject }.to change(Promotion, :count).by(1)
      end

      it 'assigns a newly created promotion as @promotion' do
        subject
        expect(assigns(:promotion)).to be_a(Promotion)
        expect(assigns(:promotion)).to be_persisted
      end

      it 'redirects to the created promotion' do
        subject
        expect(response).to redirect_to edit_campaign_path(content)
      end
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(Promotion).to receive(:save).and_return false
      end

      it 'html: redirects' do
        post :create, params: { organization_id: @org.id, promotion: { description: 'unsaved promo' } }
        expect(response).to render_template 'new'
      end

      it 'json: responds with 422 status code' do
        post :create, params: { organization_id: @org.id, promotion: { description: 'unsaved promo' } }, format: :json
        expect(response.code).to eq '422'
      end
    end
  end

  describe 'PUT update' do
    subject { put :update, params: { id: @promotion.to_param, promotion: params } }

    describe 'with valid params' do
      let(:params) { { description: 'Another description' } }

      it 'updates the requested promotion' do
        subject
        @promotion.reload
        expect(@promotion.description).to eq(params[:description])
      end

      it 'assigns the requested promotion as @promotion' do
        subject
        expect(assigns(:promotion)).to eq(@promotion)
      end

      it 'redirects to the promotion' do
        subject
        expect(response).to redirect_to edit_campaign_path(@promotion.content)
      end
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(Promotion).to receive(:save).and_return false
      end

      it 'html: renders edit page' do
        put :update, params: { id: @promotion.id, promotion: { description: 'Ocean planet' } }
        expect(response).to render_template 'edit'
      end

      it 'json: responds with 422 status code' do
        put :update, params: { id: @promotion.id, promotion: { description: 'Desert planet' } }, format: :json
        expect(response.code).to eq '422'
      end
    end
  end

  describe 'GET #new' do
    context 'when content present' do
      context 'when PromotionBanner promotable type' do
        it 'html: responds with 200 status code' do
          get :new, params: { organization_id: @org.id, promotable_type: 'PromotionBanner', content_id: @content.id }
          expect(assigns(:promotion).content).to eq @content
          expect(response.code).to eq '200'
        end

        it 'json: responds with 200 status code' do
          get :new, params: { organization_id: @org.id, promotable_type: 'PromotionBanner', content_id: @content.id }, format: :json
          expect(response.code).to eq '200'
        end
      end
    end

    context 'when no content present' do
      subject { get :new, params: { organization_id: @org.id } }

      it 'should respond with 302 status code' do
        subject
        expect(response.code).to eq '302'
      end
    end
  end
end
