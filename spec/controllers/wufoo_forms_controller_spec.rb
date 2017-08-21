require 'spec_helper'

RSpec.describe WufooFormsController, type: :controller do
  before do
    user = FactoryGirl.create :admin
    sign_in user
    @wufoo_form = FactoryGirl.create :wufoo_form
  end

  describe "GET #index" do
    subject { get :index }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "GET #new" do
    subject { get :new }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "POST #create" do
    context "when params are viable" do
      subject { post :create, wufoo_form: { form_hash: 'Destroy deathstar', call_to_action: 'V important' } }

      it "creates wufoo_form" do
        expect{ subject }.to change{
          WufooForm.count
        }.by 1
      end

      it "redirtects to wufoo_forms" do
        subject
        expect(response).to redirect_to wufoo_forms_url
      end
    end

    context "when params are not valid" do
      subject { post :create, wufoo_form: { form_hash: 'Destroy deathstar' } }

      it "does not create wufoo_form" do
        expect{ subject }.not_to change{ WufooForm.count }
      end
    end
  end

  describe "GET #edit" do
    subject { get :edit, id: @wufoo_form.id }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "PUT #update" do
    context "when update is successful" do
      subject { put :update, id: @wufoo_form, wufoo_form: { form_hash: 'Disable at least' } }

      it "redirects to wufoo_forms" do
        subject
        expect(response).to redirect_to wufoo_forms_url
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, id: @wufoo_form.id }

    it "removes specified wufoo_form" do
      subject
      expect(response).to have_http_status :ok
    end
  end
end