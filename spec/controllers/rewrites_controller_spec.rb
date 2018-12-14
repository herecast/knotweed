require 'spec_helper'

describe RewritesController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  context '#create' do
    let(:args) do
      { source: 'some-string', destination: 'another-string' }
    end
    subject! { post :create, params: { rewrite: args } }
    it 'should create the rewrite' do
      expect(assigns(:rewrite).source).to eql args[:source]
      expect(assigns(:rewrite).destination).to eql args[:destination]
    end
  end

  context '#update' do
    let(:existing_rewrite) { FactoryGirl.create :rewrite }
    let(:args) do
      { source: 'new-source',
        destination: 'new-destination' }
    end
    subject! { put :update, params: { rewrite: args, id: existing_rewrite.id } }
    it 'should update the rewrite' do
      expect(assigns(:rewrite).source).to eql args[:source]
      expect(assigns(:rewrite).destination).to eql args[:destination]
    end
  end

  context '#destroy' do
    let!(:existing_rewrite) { FactoryGirl.create :rewrite }
    subject { delete :destroy, params: { id: existing_rewrite.id }, format: :js }
    it 'should destroy the rewrite' do
      expect { subject }.to change { Rewrite.count }.from(1).to(0)
    end
  end
end
