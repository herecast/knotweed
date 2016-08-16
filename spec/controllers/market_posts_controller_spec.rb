require 'spec_helper'

describe MarketPostsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    @market_post = FactoryGirl.create :market_post
    @region_location = FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
    sign_in @user
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "redirect to market_posts index on success" do
      post 'create', market_post: {
        content_attributes: {
          title: "hello",
          raw_content: "not blank"
        },
        cost: "$5"
      }
      expect(response.code).to eq("302")
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
      expect(response).to be_success
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_success
    end

    describe 'Search Filter' do
      before do
        # setup the search query hash
        @q = {content_id_in:  "", content_title_cont: "", content_pubdate_gteq: "", content_pubdate_lteq: "",
             contact_email_cont: "", content_repositories_id_eq: ""}

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
        expect(assigns(:market_posts).length).to eq(2)
      end

      it 'filters by the content id' do
        @market_post.content.id = rand(10..20)
        @market_post.save

        @q[:content_id_in] = @market_post.content.id
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(1)
      end

      it 'does not filter by market_post id' do
        @market_post.id = 123
        @market_post.save
        @q[:content_id_in] = @market_post.id
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(0)
      end

      it 'does not search by content author email' do
        @q[:contact_email_cont] = @market_post.content.authoremail
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(0)
      end
      
      it 'filters by market_post email' do
        @q[:contact_email_cont] = @market_post.contact_email
        get :index, q: @q
        expect(assigns(:market_posts).all? do |post|
          post.contact_email == @market_post.contact_email
        end)
      end

      it 'filters by date' do
        @market_post.content.pubdate = 2.days.ago
        @market_post.save
        @q[:content_pubdate_gteq] = 3.days.ago.strftime("%Y-%m-%d")
        @q[:content_pubdate_lteq] = 1.day.ago.strftime("%Y-%m-%d")
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(1)
      end

      it 'return all market_posts' do
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(5)
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

      it 'does not dispaly multiple flash messages' do
        subject
        expect(flash.now[:notice]).to eq "Successfully updated market post #{@market_post.id}"
        expect(flash.now[:warning]).to be_nil
      end

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
