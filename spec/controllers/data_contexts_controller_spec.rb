require 'spec_helper'

describe DataContextsController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET /data_contexts' do
    context "when reset is true" do

      subject { get :index, reset: "Reset" }

      it 'should respond with 200 status code' do
        subject
        response.code.should eq '200'
        expect(assigns(:status)).to be_nil
        expect(assigns(:search)).to be_a Ransack::Search
      end
    end

    context "when query present" do
      it 'returns Loaded data contexts' do
        get :index, { q: { "context_cont" => 'MyString' }, status: "Loaded" }
        expect(assigns(:search)).to be_a Ransack::Search
        response.code.should eq '200'
      end

      it "returns Unloaded data contexts" do
        get :index, { q: { "context_cont" => 'MyString' }, status: "Unloaded" }
        expect(assigns(:search)).to be_a Ransack::Search
        response.code.should eq '200'
      end

      it "returns Archived data contexts" do
        get :index, { q: { "context_cont" => 'MyString' }, status: "Archived" }
        expect(assigns(:search)).to be_a Ransack::Search
        response.code.should eq '200'
      end
    end
  end

  describe 'GET /data_contexts/:id/edit' do
    before do
      @data_context = FactoryGirl.create :data_context
    end

    subject { get :edit, id: @data_context.id }

    it "should respond with 200 status code" do
      subject
      response.code.should eq '200'
    end
  end

  describe 'PUT /data_contexts/:id' do
    before do
      @data_contexts = FactoryGirl.create :data_context, context: 'old context'
    end

    subject { put :update, { id: @data_contexts.id, data_context: { context: 'new context' }} }

    context "when update succeeds" do
      it "should respond with a 302 status code" do
        subject
        @data_contexts.reload
        expect(@data_contexts.context).to eq 'new context'
        response.code.should eq '302'
      end
    end

    context "when update fails" do
      it "should render edit page" do
        DataContext.any_instance.stub(:update_attributes) { false }
        expect(subject).to render_template 'edit'
      end
    end
  end

  describe 'GET /data_contexts/new' do
    before do
      @data_context = FactoryGirl.create :data_context
    end

    subject { get :new }

    it 'should respond with 200 status code' do
      subject
      response.code.should eq '200'
    end
  end

  describe 'POST /data_contexts' do

    subject { post :create, { data_context: { context: 'new dc' } } }

    context "when creation succeeds" do
      it "should respond with 302 status code" do
        subject
        expect(DataContext.count).to eq 1
        response.code.should eq '302'
      end
    end

    context "when creation fails" do
      it "should render new page" do
        DataContext.any_instance.stub(:save) { false }
        expect(subject).to render_template 'new'
      end
    end
  end
end