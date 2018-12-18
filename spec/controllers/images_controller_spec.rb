# frozen_string_literal: true

require 'spec_helper'

describe ImagesController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'POST #create' do
    subject { post :create, params: { image: { image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg')) } }, format: 'js' }

    it 'should respond with 200 status code' do
      subject
      expect(Image.all.count).to eq 1
      expect(response.code).to eq '200'
    end
  end

  describe 'DELETE :destroy' do
    before do
      @image = FactoryGirl.create :image
    end

    subject { delete :destroy, params: { id: @image.id }, format: 'js' }

    it 'deletes the image' do
      expect { subject }.to change { Image.count }.by -1
      expect(response.code).to eq '200'
    end
  end

  describe 'PUT :update' do
    before do
      @image = FactoryGirl.create :image
    end

    subject { put :update, params: { id: @image.id, image: { caption: 'blarg' } }, format: 'js' }

    it 'updates the image' do
      subject
      @image.reload
      expect(@image.caption).to eq 'blarg'
      expect(response.code).to eq '200'
    end
  end
end
