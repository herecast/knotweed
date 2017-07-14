require 'spec_helper'

RSpec.describe Api::V3::Organizations::Contents::TagsController, type: :controller do

  describe "POST #create" do
    context "when no user logged in" do
      subject { post :create, { content_id: "fake", organization_id: "fake" } }

      it "returns unauthorized status" do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when organization not found" do
      before do
        user = FactoryGirl.create :user
        sign_in user
        @content = FactoryGirl.create :content
        Organization.delete_all
      end

      subject { post :create, { content_id: @content.id, organization_id: "fake" } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when content not found" do
      before do
        user = FactoryGirl.create :user
        sign_in user
        @organization = FactoryGirl.create :organization
      end

      subject { post :create, { organization_id: @organization.id, content_id: "fake" } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when content and organization found" do
      before do
        @content = FactoryGirl.create :content
        @organization = FactoryGirl.create :organization
      end

      context "when logged in user cannot manage org" do
        before do
          user = FactoryGirl.create :user
          sign_in user
        end

        subject { post :create, { organization_id: @organization.id, content_id: @content.id } }

        it "returns unauthorized status" do
          subject
          expect(response).to have_http_status :unauthorized
        end
      end

      context "when logged in user can manage org" do
        before do
          user = FactoryGirl.create :user
          sign_in user
          user.add_role(:manager, @organization)
        end

        subject { post :create, { organization_id: @organization.id, content_id: @content.id } }

        it "creates tag" do
          expect{ subject }.to change{
            @organization.tagged_contents.count
          }.by 1
        end
      end

      context "when logged in user is admin" do
        before do
          admin = FactoryGirl.create :admin
          sign_in admin
        end

        subject { post :create, { organization_id: @organization.id, content_id: @content.id } }

        it "creates tag" do
          expect{ subject }.to change{
            @organization.tagged_contents.count
          }.by 1
        end
      end
    end
  end

  describe "DELETE #destroy" do
    context "when no user logged in" do
      subject { delete :destroy, { content_id: "fake", organization_id: "fake" } }

      it "returns unauthorized status" do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when organization not found" do
      before do
        user = FactoryGirl.create :user
        sign_in user
        @content = FactoryGirl.create :content
        Organization.delete_all
      end

      subject { delete :destroy, { content_id: @content.id, organization_id: 1 } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when content not found" do
      before do
        user = FactoryGirl.create :user
        sign_in user
        @organization = FactoryGirl.create :organization
      end

      subject { delete :destroy, { organization_id: @organization.id, content_id: 1 } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when content and organization found" do
      before do
        @content = FactoryGirl.create :content
        @organization = FactoryGirl.create :organization
        @organization.tagged_contents << @content
      end

      context "when logged in user cannot manage org" do
        before do
          user = FactoryGirl.create :user
          sign_in user
        end

        subject { delete :destroy, { organization_id: @organization.id, content_id: @content.id } }

        it "returns unauthorized status" do
          subject
          expect(response).to have_http_status :unauthorized
        end
      end

      context "when logged in user can manage org" do
        before do
          user = FactoryGirl.create :user
          sign_in user
          user.add_role(:manager, @organization)
        end

        subject { delete :destroy, { organization_id: @organization.id, content_id: @content.id } }

        it "creates tag" do
          expect{ subject }.to change{
            @organization.tagged_contents.count
          }.by -1
        end
      end

      context "when logged in user is admin" do
        before do
          admin = FactoryGirl.create :admin
          sign_in admin
        end

        subject { delete :destroy, { organization_id: @organization.id, content_id: @content.id } }

        it "creates tag" do
          expect{ subject }.to change{
            @organization.tagged_contents.count
          }.by -1
        end
      end
    end
  end
end