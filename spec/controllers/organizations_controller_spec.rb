require 'spec_helper'

describe OrganizationsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe '#index' do
    context 'Given the parameter "reset"' do
      before do
        session[:organizations_search] = {}
        get :index, {reset: true}
      end

      it 'sets session[:organizations_search] to nil' do
        expect(session[:organizations_search]).to be_nil
      end
    end

    context 'Given parameter "q"' do
      let(:q) { {'fake' => "search"} }

      subject do
        get :index, {q: q}
      end

      it 'sets session[:organizations_search] to q' do
        subject
        expect(session[:organizations_search]).to eql q
      end

      it 'does search' do
        search = double(result: Organization )
        expect(Organization).to receive(:ransack).with(q).and_return(search)

        subject

        expect(assigns(:search)).to eql search
      end
    end

    context 'when searching by orgs that can publish news' do
      before do
        @news_org = FactoryGirl.create :organization, can_publish_news: true
        @org = FactoryGirl.create :organization
      end
      
      it 'retuns only organizations that can publish news when true' do
        get :index, q: { "show_news_publishers" => "1" }
        expect(assigns(:organizations).all? { |org| org.can_publish_news == true }).to eq true
      end

      it 'retuns all organizations' do
        get :index, q: { "show_news_publishers" => "0" }
        expect(assigns(:organizations).count).to eq Organization.count
      end
    end

    context 'no parameters; session[:organizations_search]' do
      before do
        session[:organizations_search] = {fake: "search"}
      end

      it 'searches with the saved session search parameters' do
        search = double(result: Organization )
        expect(Organization).to receive(:ransack).with(
          session[:organizations_search]
        ).and_return(search)

        get :index
      end
    end
    
    context 'including child organizations' do
      let!(:parent_organization) { FactoryGirl.create :organization }
      let!(:child_organization) { FactoryGirl.create(:organization, parent_id: parent_organization.id) }

      it 'retuns child organizations' do
        q = { 'id_eq' => parent_organization.id, 'include_child_organizations' => '1' }
        get :index, q: q
        expect(assigns(:organizations).length).to eq(2)
      end

      it 'does not include child organizations' do
        q = { 'id_eq' => parent_organization.id  }
        get :index, q: q
        expect(assigns(:organizations).length).to eq(1)
      end

      context 'when searching by can_publish_news' do
        let!(:parent_news_org) { FactoryGirl.create :organization, can_publish_news: true }
        let!(:child_news_org) { FactoryGirl.create :organization, parent_id: parent_news_org.id }
        
        it 'retuns child organizations for orgs that can publish news' do
          q = { 'include_child_organizations' => '1',
                'can_publish_news_true' => '1' }
          get :index, q: q
          expect(assigns(:organizations).length).to eq(2)
          expect(assigns(:organizations))
          ids = assigns(:organizations).map(&:id)
          expect(ids).to include parent_news_org.id
          expect(ids).to include child_news_org.id
        end

      end
    end

    context 'when searching by can_publish_news' do
      let!(:news_org) { FactoryGirl.create :organization, can_publish_news: true }
      
      it 'returns records where can_publish_news is true' do
        get :index, q: { "can_publish_news_true" => 1 }
        expect(assigns(:organizations).first).to eq(news_org)
      end
    
    end
  end

  describe '#new' do
    it 'will render organizations/new' do
      get :new
      expect(response).to render_template('organizations/new')
    end

    context '?short_form=true' do
      it 'renders partial short_form' do
        get :new, short_form: true
        expect(response).to render_template('organizations/partials/_short_form')
      end
    end
  end

  describe '#edit' do
    let(:organization) { FactoryGirl.create :organization }
    it 'renders "edit"' do
      get :edit, {id: organization.id}
      expect(response).to render_template('organizations/edit')
    end
  end

  describe '#update' do
    let(:organization) { FactoryGirl.create :organization }
    let(:update_attrs) { {'name' => "new name"} }
    before do
      allow(Organization).to receive(:find).and_return(organization)
    end

    it 'updates the model' do
      put :update, {id: organization.id, organization: update_attrs}
      expect(organization.name).to eql 'new name'
    end

    it 'redirects to organizations_path' do
      put :update, {id: organization.id, organization: update_attrs}
      expect(response).to redirect_to(organizations_path)
    end

    context 'validation failure' do
      before do
        allow(organization).to receive(:update_attributes).and_return(false)
      end
      it 're renders edit' do
        put :update, {id: organization.id, organization: update_attrs}
        expect(response).to render_template('organizations/edit')
      end
    end

    context 'when the organization is a business' do
      let(:organization) { FactoryGirl.create :organization, org_type: "Business" }
      let!(:business_location) { FactoryGirl.create :business_location, organization_id: organization.id }
      let!(:business_profile) { FactoryGirl.create :business_profile, 
                                business_location_id: business_location.id }
      let!(:business_category) { FactoryGirl.create :business_category }

      it 'updates a business_location' do
        business_location_attrs =  { business_location_id: business_location.id, email: 'org_mgr@subtext.org', hours: ["Mo-Th|16:00-20:00"] }
        put :update, { id: organization.id, organization: update_attrs,  business_location: business_location_attrs } 
        expect(organization.business_locations.first.email).to eq 'org_mgr@subtext.org'
        expect(organization.business_locations.first.hours).to eq ["Mo-Th|16:00-20:00"]
      end
      
      it 'updates the business_categories' do
        business_location_attrs =  { business_location_id: business_location.id, hours: [""] }
        put :update, { id: organization.id, organization: update_attrs, 
                       business_location: business_location_attrs,
                       business_profile: { business_category_ids: ['', business_category.id] } } 
        expect(business_profile.business_categories.first.id).to eq business_category.id 
      end

      it 'updates the business profile title' do
        put :update, { id: organization.id, organization: update_attrs.merge('profile_title' => 'My Profile') }
        expect(organization.profile_title).to eq 'My Profile'
      end
    end
  end 

  describe '#create' do
    context 'with valid attributes' do
      let(:org_attrs) { FactoryGirl.attributes_for(:organization) }
      it 'creates an organization' do
        expect {
          post :create, organization: org_attrs
        }.to change {
          Organization.count
        }.by(1)
      end

      context "given organization[contact_list] csv parameter" do
        let(:contacts){ FactoryGirl.create_list :contact, 2 }
        let(:contact_list) { contacts.map(&:id).join(',') }

        it "converts them to contact_ids" do
          post :create, organization: org_attrs.merge(contact_list: contact_list)
          expect(assigns(:organization).contact_ids).to eql contacts.map(&:id)
        end
      end

      context "given organization[business_location_list] csv parameter" do
        let(:locations){ FactoryGirl.create_list :business_location, 2 }
        let(:location_list) { locations.map(&:id).join(',') }

        it "converts them to business_location_ids" do
          send_params = {organization: org_attrs.merge(business_location_list: location_list)}
          post :create, send_params
          expect(assigns(:organization).business_location_ids).to eql locations.map(&:id)
        end
      end
    end

    context 'with invalid attributes' do
      before do
        allow_any_instance_of(Organization).to receive(:save).and_return(false)
      end

      it 're-renders "new" template' do
        post :create, organization: {name: nil}
        expect(response).to render_template('organizations/new')
      end
    end
  end

  describe '#destroy' do
    let(:organization) { FactoryGirl.create :organization }
    before do
      allow(Organization).to receive(:find).and_return(organization)
    end

    it 'destroys record' do
      expect(organization).to receive(:destroy)
      delete :destroy, id: organization.id
    end
  end

  describe '#business_location_options' do
    let!(:organization) { FactoryGirl.create :organization }
    let!(:biz_locations) { FactoryGirl.create_list :business_location, 2, organization: organization }
    context 'organization has some business locations' do
      it 'sets up the rjs view with business location options' do
        xhr :get, :business_location_options, organization_id: organization.id, format: :js

        biz_options = assigns(:business_locations)
        expect(biz_options).to include([nil,nil])
        biz_locations.each do |bl|
          expect(biz_options).to include([bl.select_option_label, bl.id])
        end
      end
    end
  end
end
