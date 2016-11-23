require 'rails_helper'

RSpec.describe MarketCategoriesController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    # MarketCategory.destroy_all
  end

  let(:valid_attributes) {{
    name: 'My Market Category',
    query: 'Sample Query',
    category_image: 'path/to/image',
    detail_page_banner: 'path/to/bigger_image',
    featured: false
  }}
      
  let(:invalid_attributes)  {{
    name: '',
    category_image: 'path/to/image',
    detail_page_banner: 'path/to/bigger_image',
    featured: false
  }}
  
  describe "GET #index" do
    it "assigns all market_categories as @market_categories" do
      market_category = MarketCategory.create! valid_attributes
      get :index
      expect(assigns(:market_categories)).to eq([market_category])
    end
  end

  describe "GET #new" do
    it "assigns a new market_category as @market_category" do
      get :new
      expect(assigns(:market_category)).to be_a_new(MarketCategory)
    end
  end

  describe "GET #edit", elasticsearch: true do
    let!(:persisted_market_category) { FactoryGirl.create :market_category, query: 'winter tires' }
    let!(:market_post_content) { FactoryGirl.create :content, title: 'Winter tires for sale', 
      content_category: FactoryGirl.create(:content_category, name: 'market') }
    let!(:market_post) { FactoryGirl.create :market_post, content: market_post_content }
    
    it "assigns the requested market_category as @market_category" do
      get :edit, id: persisted_market_category
      expect(assigns(:market_category)).to eq(persisted_market_category)
    end
    
    context "when query is nil" do
      let!(:empty_query_category) { FactoryGirl.create :market_category, query: nil }

      it 'does not populate @search_preview with the search results' do
        get :edit, id: empty_query_category
        expect(assigns(:search_preview)).to be_nil
      end

    end

    context "when query is present" do
      it 'populates @search_preview with search results' do
        get :edit, id: persisted_market_category
        expect(assigns(:market_category)).to_not be_nil
      end

      it '@search_results contain values for the content result' do
        get :edit, id: persisted_market_category
        search_result = assigns(:search_preview).first
        expect(search_result).to eq market_post_content
        expect(search_result.channel).to eq market_post
      end

      it 'sets the count field to the number of search results' do
        get :edit, id: persisted_market_category
        expect(assigns(:market_category).result_count).to eq 1
      end
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new MarketCategory" do
        expect {
          post :create, market_category: valid_attributes
        }.to change(MarketCategory, :count).by(1)
      end

      it "assigns a newly created market_category as @market_category" do
        post :create, market_category: valid_attributes
        expect(assigns(:market_category)).to be_a(MarketCategory)
        expect(assigns(:market_category)).to be_persisted
      end

      it "redirects to the market_category edit page" do
        post :create, market_category: valid_attributes.merge(name: 'Edit Category')
        market_category = MarketCategory.find_by(name: 'Edit Category')
        expect(response).to redirect_to(edit_market_category_path(market_category))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved market_category as @market_category" do
        post :create, market_category: invalid_attributes
        expect(assigns(:market_category)).to be_a_new(MarketCategory)
      end

      it "re-renders the 'new' template" do
        post :create, market_category: invalid_attributes
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {{name: 'Updated Market Category Name'}}

      it "updates the requested market_category" do
        market_category = MarketCategory.create! valid_attributes
        put :update, id: market_category, market_category: new_attributes
        market_category.reload
        expect(assigns(:market_category).name).to eq ('Updated Market Category Name')
      end

      it "assigns the requested market_category as @market_category" do
        market_category = MarketCategory.create! valid_attributes
        put :update, id: market_category, market_category: valid_attributes
        expect(assigns(:market_category)).to eq(market_category)
      end

      it "redirects to the market_category" do
        market_category = MarketCategory.create! valid_attributes
        put :update, id: market_category, market_category: valid_attributes
        expect(response).to redirect_to(market_categories_url)
      end
    end

    context "with invalid params" do
      it "assigns the market_category as @market_category" do
        market_category = MarketCategory.create! valid_attributes
        put :update, id: market_category, market_category: invalid_attributes
        expect(assigns(:market_category)).to eq(market_category)
      end

      it "re-renders the 'edit' template" do
        market_category = MarketCategory.create! valid_attributes
        put :update, id: market_category, market_category: invalid_attributes
        expect(response).to render_template("edit")
      end
    end

  end

  describe "DELETE #destroy" do
    it "destroys the requested market_category" do
      market_category = MarketCategory.create! valid_attributes
      expect {
        delete :destroy, id: market_category.to_param
      }.to change(MarketCategory, :count).by(-1)
    end

    it "redirects to the market_categories list" do
      market_category = MarketCategory.create! valid_attributes
      delete :destroy, id: market_category
      expect(response).to redirect_to(market_categories_url)
    end
  end

end
