require 'spec_helper'

describe MessagesController do
  let(:message)        { FactoryGirl.create(:message) }
  let(:attrs)          { FactoryGirl.attributes_for(:message) }
  let(:update_attrs)   { attrs.merge(content: "Updated #{attrs[:content]}") }

  before do
    sign_in FactoryGirl.create(:admin)
  end

  describe 'GET index' do
    subject! { get :index }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'POST create' do
    subject { post :create, message: attrs }

    it 'should create a message record' do
      expect { subject }.to change { Message.count }.by 1
    end

    context "when creation fails" do
      subject { post :create, message: {content: "my content"} }

      it "renders new page" do
        subject
        expect(response).to render_template 'new'
      end
    end
  end

  describe 'GET edit' do
    subject! { get :edit, id: message }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'PUT update' do
    subject { put :update, id: message, message: update_attrs }

    it 'should update the message' do
      expect{subject}.to change{message.reload.content}.to update_attrs[:content]
    end

    context 'when update fails' do
      subject { put :update, id: message, message: {content: nil} }

      it "renders edit page" do
        subject
        expect(response).to render_template 'edit'
      end
    end
  end
end
