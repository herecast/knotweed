require 'spec_helper'

describe PromotionsController do 
  include Devise::TestHelpers

  before do
    ImageUploader.storage = :file
    user = FactoryGirl.create(:admin)
    sign_in user
    @pub = FactoryGirl.create(:publication)
    @content = FactoryGirl.create(:content)
    Promotion.any_instance.stub(:update_active_promotions).and_return(true)
    @promotion = FactoryGirl.create(:promotion, publication: @pub, content: @content)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  describe "GET index" do
    subject { get :index, publication_id: @pub }
    it "assigns all promotions as @promotions" do
      subject
      assigns(:promotions).should eq([@promotion])
    end
  end

  describe "GET show" do
    subject { get :show, { id: @promotion.to_param } }
    it "assigns the requested promotion as @promotion" do
      subject
      assigns(:promotion).should eq(@promotion)
    end
  end

  describe "GET edit" do
    subject { get :edit, {id: @promotion.to_param } }
    it "assigns the requested promotion as @promotion" do
      subject
      assigns(:promotion).should eq(@promotion)
    end
  end

  describe "POST create" do
    let (:options) do 
      { description: "Another bad promotion" }
    end
    subject { post :create, { promotion: options, publication_id: @pub } }
    describe "with valid params" do
      it "creates a new Promotion" do
        expect { subject }.to change(Promotion, :count).by(1)
      end

      it "assigns a newly created promotion as @promotion" do
        subject
        expect(assigns(:promotion)).to be_a(Promotion)
        expect(assigns(:promotion)).to be_persisted
      end

      it "redirects to the created promotion" do
        subject
        expect(response).to redirect_to(Promotion.last)
      end
    end
  end

  describe "PUT update" do
    subject { put :update, { id: @promotion.to_param, promotion: params} }
    describe "with valid params" do
      let(:params) do
        { active: false,
          description: 'Another description'
        } 
      end
      it "updates the requested promotion" do
        subject
        @promotion.reload
        expect(@promotion.active).to eq(params[:active])
        expect(@promotion.description).to eq(params[:description])
      end

      it "assigns the requested promotion as @promotion" do
        subject
        expect(assigns(:promotion)).to eq(@promotion)
      end

      it "redirects to the promotion" do
        subject
        expect(response).to redirect_to(@promotion)
      end
    end
  end

  describe "DELETE destroy" do
    subject { delete :destroy, {id: @promotion.to_param} }
    it "destroys the requested promotion" do
      expect { subject }.to change(Promotion, :count).by(-1)
    end

    it "redirects to the promotions list" do
      expect(subject).to redirect_to(publication_promotions_path @pub)
    end
  end

end
