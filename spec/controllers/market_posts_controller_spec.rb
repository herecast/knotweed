require 'spec_helper'

describe MarketPostsController do
  before do
    @user = FactoryGirl.create :admin
    @market_post = FactoryGirl.create :market_post
    @region_location = FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
    sign_in @user
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "redirect to market_posts index on success" do
      c = FactoryGirl.create :content
      post 'create', market_post: {
        content_attributes: {
          title: "hello",
          raw_content: "not blank"
        },
        cost: "$5"
      }
      response.code.should eq("302")
    end

    context "when market post is published" do
      let(:repository) { FactoryGirl.create :repository }

      subject { post :create, continue_editing: 'true', market_post: { content_attributes: { title: 'hi', raw_content: 'not blank' } } }

      it "flashes success notice" do
        allow_any_instance_of(User).to receive(:default_repository).and_return (repository)
        allow_any_instance_of(Content).to receive(:publish).and_return true

        subject

        expect(flash.now[:notice]).to include 'successfully'
        expect(response.code).to eq '302'
      end
    end

    context "when market post save unsuccessful" do
      let(:content) { FactoryGirl.create :content }

      subject { post :create, market_post: {} }

      it "renders new page" do
        allow_any_instance_of(MarketPost).to receive(:save).and_return false
        allow_any_instance_of(MarketPost).to receive(:content).and_return content
        subject
        expect(response).to render_template 'new'
      end
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: @market_post.id
      response.should be_success
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get :index
      response.should be_success
    end

    describe 'Search Filter' do
      before do
        # setup the search query hash
        @q = {id_in:  "", content_title_cont: "", pubdate_gteq: "", pubdate_lteq: "",
              content_authors_cont: "", content_repositories_id_eq: ""}

        # market_posts to filter against
        @market_post1 = FactoryGirl.create :market_post
        @market_post2 = FactoryGirl.create :market_post
        @market_post3 = FactoryGirl.create :market_post
        @market_post4 = FactoryGirl.create :market_post
      end

      it 'return selected titles' do
        @market_post4.title = 'ZZZZ';
        @market_post4.save
        @market_post3.title = 'ZZab';
        @market_post3.save

        @q[:content_title_cont] = 'ZZ'
        get :index, q: @q
        assigns(:market_posts).length.should == 2
      end

      it 'return all market_posts' do
        get :index, q: @q
        assigns(:market_posts).length.should == 5
      end
    end

    context "when param has reset" do

      subject { get :index, reset: 'true' }

      it "returns no market posts" do
        subject
        expect(assigns(:market_posts)).to eq []
      end
    end
  end

  describe "GET :show" do

    subject { get :show, id: @market_post.id }

    it "redirects to edit" do
      subject
      expect(response.code).to eq '302'
      expect(response).to redirect_to edit_market_post_path
    end
  end

  describe "PUT :update" do

    context "when successful update" do
      let(:repository) { FactoryGirl.create :repository }

      subject { put :update, create_new: 'true', id: @market_post.id, market_post: { status: 'cool' } }

      context "when successful publish" do
        it "redirects" do
          allow_any_instance_of(User).to receive(:default_repository).and_return repository
          allow_any_instance_of(Content).to receive(:publish).and_return true

          subject

          expect(@market_post.reload.status).to eq 'cool'
          expect(flash.now[:notice]).to include 're-published'
          expect(response.code).to eq '302'
        end
      end

      context "when failed publish" do
        it "redirects" do
          subject
          expect(@market_post.reload.status).to eq 'cool'
          expect(response.code).to eq '302'
        end
      end
    end

    context "when unsuccessful update" do

      subject { put :update, id: @market_post.id }

      it "renders edit page" do
        allow_any_instance_of(MarketPost).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

end
