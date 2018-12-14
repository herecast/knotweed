require 'spec_helper'

describe Users::ArchivingsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  let(:user) { FactoryGirl.create :user }
  before { sign_in admin }

  describe 'GET new' do
    subject! { get :new, params: { user_id: user.id } }

    it 'should respond with a 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'POST create' do
    subject { post :create, params: { user_id: user.id } }

    it 'should update the user record as archived' do
      expect { subject }.to change { user.reload.archived? }.to true
    end

    context 'with new_content_owner passed' do
      let(:new_content_owner) { FactoryGirl.create :user }
      let!(:contents) { FactoryGirl.create_list :content, 3 }

      subject { post :create, params: { user_id: user.id, new_content_owner: new_content_owner.email } }

      it 'should reassign all the content belonging to the original user' do
        Content.update_all(created_by_id: user.id)
        subject
        expect(Content.where(created_by: new_content_owner)).to match_array contents
      end
    end
  end
end
