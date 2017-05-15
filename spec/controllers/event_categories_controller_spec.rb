require 'rails_helper'

RSpec.describe EventCategoriesController, type: :controller do
  before do
    user = FactoryGirl.create :admin
    sign_in user
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
    let(:params) { { event_category: { name: 'Bars on Tatooine', query: 'bars' } } }

    context "with bad request" do
      before do
        allow_any_instance_of(EventCategory).to receive(:save).and_return false
      end

      subject { post :create, params }

      it "expect no event category to be created" do
        expect{ subject }.not_to change{
          EventCategory.count
        }
      end
    end

    context "with good request" do
      subject { post :create, params }

      it "creates new event category" do
        expect{ subject }.to change{
          EventCategory.count
        }.by 1
      end
    end
  end

  describe "GET #edit" do
    context "without valid id param" do
      subject { get :edit, id: 42 }

      it "raises error" do
        expect{ subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with valid id param" do
      before do
        @event_category = FactoryGirl.create :event_category
      end

      subject { get :edit, id: @event_category.id }

      it "returns ok status" do
        subject
        expect(response).to have_http_status :ok
      end
    end
  end

  describe "PUT #update" do
    context "without valid id param" do
      subject { put :update, id: 42 }

      it "raises error" do
        expect{ subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with valid id param" do
      before do
        @event_category = FactoryGirl.create :event_category,
          name: 'Cantinas on Death Start'
      end

      context "when update params are invalid" do
        let(:params) { { id: @event_category.id, event_category: { name: nil } } }

        subject { put :update, params }

        it "does not update event category" do
          expect{ subject }.not_to change{
            @event_category.reload.name
          }
        end
      end

      context "when params are valid" do
        let(:new_name) { "Death Star Mexican restaurants" }
        let(:params) { { id: @event_category.id, event_category: { name: new_name } } }

        subject { put :update, params }

        it "updates event category" do
          expect{ subject }.to change{
            @event_category.reload.name
          }.to new_name
        end
      end
    end
  end

  describe "DELETE #destroy" do
    context "when id param is not valid" do
      subject { delete :destroy, id: 42 }

      it "raises error" do
        expect{ subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "when id param is valid" do
      before do
        @event_category = FactoryGirl.create :event_category
      end

      subject { delete :destroy, id: @event_category.id }

      it "deletes matching record" do
        expect{ subject }.to change{
          EventCategory.count
        }.by -1
      end
    end
  end
end
