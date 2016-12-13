require 'rails_helper'

RSpec.describe ListservContentsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  let(:listserv) { FactoryGirl.create(:subtext_listserv) }

  let(:valid_attributes) {
    {
      sender_name: 'Mary Poppins',
      sender_email: 'mary@example.org',
      subject: 'New event!',
      body: 'A really long description',
      content_category_id: FactoryGirl.create(:content_category).id,
      verified_at: Time.now,
      content_id: FactoryGirl.create(:content).id,
      listserv_id: FactoryGirl.create(:subtext_listserv).id
    }
  }

  describe "GET #index" do
    it "assigns all listserv_contents as @listserv_contents" do
      listserv_content = ListservContent.create! valid_attributes.merge(
        verify_ip: '1.1.1.1'
      )
      get :index, {}
      expect(assigns(:listserv_contents)).to eq([listserv_content])
    end

    it 'paginates' do
      FactoryGirl.create_list :listserv_content, 3
      get :index, page: 1, per_page: 2
      expect(assigns(:listserv_contents).count).to eql 2
    end

    it 'orders by newest first' do
      listserv_contents = []
      3.times do |i|
        listserv_contents << FactoryGirl.create(:listserv_content,
          created_at: 2.hours.ago + i.minutes
                                               )
      end

      get :index
      expect(assigns(:listserv_contents).first).to eql listserv_contents.last
    end

    describe 'Searching' do
      let!(:listserv1) { FactoryGirl.create :subtext_listserv }
      let!(:listserv1_content) { FactoryGirl.create :listserv_content, listserv: listserv1 }

      let!(:category1) { FactoryGirl.create :content_category }
      let!(:category1_content) { FactoryGirl.create :listserv_content, content_category: category1 }

      let!(:verified_content) {
        FactoryGirl.create :listserv_content,
          verified_at: Time.current,
          verify_ip: '1.1.1.1'
      }

      let!(:content_by_email) { FactoryGirl.create :listserv_content, sender_email: 'search123@inbox.com' }

      let!(:content_by_subject) { FactoryGirl.create :listserv_content, subject: 'subject123 and more' }

      let!(:content_by_created_at) { FactoryGirl.create :listserv_content, created_at: 1.day.ago }

      it 'filters by listserv' do
        get :index, q: {listserv_id_eq: listserv1.id}
        expect(assigns(:listserv_contents).to_a).to eql [listserv1_content]
      end

      it 'filters by category' do
        get :index, q: {content_category_id_eq: category1.id}
        expect(assigns(:listserv_contents).to_a).to eql [category1_content]
      end

      it 'filters by verified status' do
        get :index, q: {verified_at_not_null: 1}
        expect(assigns(:listserv_contents).to_a).to eql [verified_content]
      end

      it 'filters by partial sender_email' do
        get :index, q: {sender_email_cont: 'search123'}
        expect(assigns(:listserv_contents).to_a).to eql [content_by_email]
      end

      it 'filters by partial subject' do
        get :index, q: {subject_cont: 'subject123'}
        expect(assigns(:listserv_contents).to_a).to eql [content_by_subject]
      end

      it 'filters by created_at range' do
        beginning = (1.day.ago - 1.hour)
        ending = (1.day.ago + 1.hour)
        get :index, q: {created_at_gteq: beginning, created_at_lteq: ending}
        expect(assigns(:listserv_contents).to_a).to eql [content_by_created_at]
      end
    end
  end

  describe "GET #show" do
    it "assigns the requested listserv_content as @listserv_content" do
      listserv_content = ListservContent.create! valid_attributes.merge(
        verify_ip: "1.1.1.1"
      )
      get :show, {:id => listserv_content.to_param}
      expect(assigns(:listserv_content)).to eq(listserv_content)
    end
  end

  describe "GET #new" do
    it "assigns a new listserv_content as @listserv_content" do
      get :new, {}
      expect(assigns(:listserv_content)).to be_a_new(ListservContent)
    end
  end

  describe "GET #edit" do
    it "assigns the requested listserv_content as @listserv_content" do
      listserv_content = ListservContent.create! valid_attributes.merge(
        verify_ip: '1.1.1.1'
      )
      get :edit, {:id => listserv_content.to_param}
      expect(assigns(:listserv_content)).to eq(listserv_content)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new ListservContent" do
        expect {
          post :create, {:listserv_content => valid_attributes}
        }.to change(ListservContent, :count).by(1)
      end

      it "assigns a newly created listserv_content as @listserv_content" do
        post :create, {:listserv_content => valid_attributes}
        expect(assigns(:listserv_content)).to be_a(ListservContent)
        expect(assigns(:listserv_content)).to be_persisted
      end

      it "redirects to the created listserv_content" do
        post :create, {:listserv_content => valid_attributes}
        expect(response).to redirect_to(ListservContent.last)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "updates the requested listserv_content" do
        listserv_content = FactoryGirl.create(:listserv_content)
        attr_keys = valid_attributes.keys.map(&:to_s)
        expect{
          put :update, {:id => listserv_content.to_param, :listserv_content => valid_attributes}
        }.to change{
          listserv_content.reload.attributes.slice(*attr_keys).values
        }
      end

      it "assigns the requested listserv_content as @listserv_content" do
        listserv_content = ListservContent.create! valid_attributes.merge(
          verify_ip: '1.1.1.1'
        )
        put :update, {:id => listserv_content.to_param, :listserv_content => valid_attributes}
        expect(assigns(:listserv_content)).to eq(listserv_content)
      end

      it "redirects to the listserv_content" do
        listserv_content = ListservContent.create! valid_attributes.merge(
          verify_ip: '1.1.1.1'
        )
        put :update, {:id => listserv_content.to_param, :listserv_content => valid_attributes}
        expect(response).to redirect_to(listserv_content)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:listserv_content) {
      ListservContent.create! valid_attributes.merge(
        verify_ip: '1.1.1.1'
      )
    }

    it "soft deletes the requested listserv_content" do
      delete :destroy, {:id => listserv_content.to_param}
      deleted_content = ListservContent.unscoped.find(listserv_content.id)
      expect(deleted_content.deleted_at).to be_a ActiveSupport::TimeWithZone
    end

    it "sets deleted_by column to current user name" do
      delete :destroy, {:id => listserv_content.to_param}
      deleted_content = ListservContent.unscoped.find(listserv_content.id)
      expect(deleted_content.deleted_by).to eql @user.name
    end

    it "redirects to the listserv_contents list" do
      delete :destroy, {:id => listserv_content.to_param}
      expect(response).to redirect_to(listserv_contents_url)
    end
  end

  describe 'POST #undelete' do
    let!(:listserv_content) {
      FactoryGirl.create :listserv_content,
        deleted_at: Time.current,
        deleted_by: "Mr. Test"
    }

    subject{ post :undelete, {id: listserv_content.to_param} }

    it 'reverses a soft delete' do
      expect{subject}.to change{
        listserv_content.reload.deleted_at
      }.to(nil).and change{
        listserv_content.reload.deleted_by
      }.to(nil)
    end

  end

end
