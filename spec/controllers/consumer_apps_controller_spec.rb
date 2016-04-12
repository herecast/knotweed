require 'spec_helper'

describe ConsumerAppsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET index' do
    before { FactoryGirl.create_list :consumer_app, 3 }
    subject! { get :index }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the consumer apps' do
      expect(assigns(:consumer_apps)).to eq ConsumerApp.all
    end
  end

  describe 'GET edit' do
    before { @app = FactoryGirl.create :consumer_app }
    subject! { get :edit, id: @app.id }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end

    it 'should load the consumer app' do
      expect(assigns(:consumer_app)).to eq @app
    end
  end

  describe 'GET new' do
    subject! { get :new }

    it 'should respond with 200 status' do
      expect(response.code).to eq '200'
    end
  end

  describe 'PUT update' do
    before do
      @app = FactoryGirl.create :consumer_app
      @update_params = { name: 'Fake Updated Name' }
    end

    subject { put :update, id: @app.id, consumer_app: @update_params }

    it 'should update the consumer app' do
      expect{subject}.to change{@app.reload.name}.to @update_params[:name]
    end

    context 'when update fails' do
      it "renders edit page" do
        allow_any_instance_of(ConsumerApp).to receive(:update_attributes).and_return false
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

  describe 'POST create' do
    subject { post :create, consumer_app: { name: 'App Name',
                                            uri: 'http://www.google.com' } }

    it 'should create a consumer app record' do
      expect{subject}.to change{ConsumerApp.count}.by 1
    end

    context "when creation fails" do
      it "renders new page" do
        allow_any_instance_of(ConsumerApp).to receive(:save).and_return false
        subject
        expect(response).to render_template 'new'
      end
    end
  end

end
