require 'spec_helper'

describe EventsController, :type => :controller  do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'edit' do
    before do
      @event = FactoryGirl.create :event
      @next_event = FactoryGirl.create :event
    end

    context "when no index param present" do

      subject { get :edit, id: @event.id }

      it 'should respond with 200 status' do
        subject
        expect(response.code).to eq '200'
      end
    end

    context "when index param present" do

      subject { get :edit, { id: @event.id, index: 0 } }

      it "finds next event id" do
        EventInstance.stub_chain(:ransack, :result, :joins, :order, :page, :per, :select) { [@event, @next_event] }
        subject
        expect(assigns(:next_event_id)).to eq @next_event.id
      end

      it "jumps to next page if necessary" do
        EventInstance.stub_chain(:ransack, :result, :joins, :order, :page, :per, :select) { [@next_event, nil] }
        subject
        expect(assigns(:next_event_id)).to eq @next_event.id
      end
    end
  end

  describe 'new' do

    context "when no unchannelized content param present" do

      subject  { get :new }

      it 'should respond with 200 status' do
        subject
        expect(response.code).to eq '200'
      end
    end

    context "when unchannelized content param present" do
      before do
        @content = FactoryGirl.create :content, title: 'title'
      end

      subject { get :new, unchannelized_content_id: @content.id }

      it 'duplicates unchannelized content into event' do
        subject
        event = assigns(:event)
        expect(event.title).to eq 'title'
      end
    end
  end

  describe 'index' do
    context "when search is reset" do

      subject { get :index, reset: 'Reset' }

      it "should return no search results" do
        subject
        expect(assigns(:event_instances)).to eq []
        expect(response.code).to eq '200'
      end
    end

    it 'should respond with a 200 status' do
      get :index
      expect(response.code).to eq '200'
    end

    describe 'Features Filter' do
      before do
        # setup the search query hash
        @q = {event_content_id_in:  "", event_content_title_cont: "", event_content_pubdate_gteq: "", event_content_pubdate_lteq: "",
             event_content_organization_id_in: [""], event_content_authors_cont: "", start_date_gteq: "", start_date_lteq: "",
             event_content_repositories_id_eq: "", event_featured_true: ""}

        # events to filter against
        @event1 = FactoryGirl.create :event
        @event2 = FactoryGirl.create :event
        @event3 = FactoryGirl.create :event
        @event4 = FactoryGirl.create :event
      end

      it 'return featured events' do
        @event4.featured = true;
        @event4.save

        @q[:event_featured_true] = "1"
        get :index, q: @q
        assigns(:event_instances).length.should == 1
      end

      it 'return all events' do
        get :index, q: @q
        assigns(:event_instances).length.should == 4
      end

      it 'return non-featured events' do
        @event4.featured = true;
        @event4.save

        @q[:event_featured_true] = "0"
        get :index, q: @q
        assigns(:event_instances).length.should == 3
      end
    end
  end

  describe 'POST #create' do

    context 'when unchannelized_content_id param present' do
      before do
        @content = FactoryGirl.create :content, images: [ FactoryGirl.create(:image) ]
        @uv = FactoryGirl.create :location, id: 77
      end

      subject { post :create, { unchannelized_content_id: @content.id, event: { content_attributes: {}, event_instances_attributes: [[{}, { start_date: Date.today, start_day: DateTime.now, start_time: Time.now  }]] } } }

      context "when event does not save" do
        it "renders new" do
          Location.stub_chain(:joins, :where) { Location.all }
          subject
          expect(response).to render_template 'new'
        end
      end

      context "when event saves and publishes" do
        it "should respond with flash and 302 status code" do
          Event.any_instance.stub(:save) { true }
          Fog::Storage.stub(:new) { 'fog' }
          String.any_instance.stub(:copy_object) {}
          User.any_instance.stub(:default_repository) { 'some value' }
          Content.any_instance.stub(:publish) { true }

          subject

          expect(flash.now[:notice]).to be_true
          expect(response.code).to eq '302'
        end
      end

      context "when event saves but does not publish" do
        it "should respond with flash warning and 302 status code" do
          Event.any_instance.stub(:save) { true }
          Fog::Storage.stub(:new) { 'fog' }
          String.any_instance.stub(:copy_object) {}
          User.any_instance.stub(:default_repository) { 'some value' }
          Content.any_instance.stub(:publish) { false }

          subject

          expect(flash.now[:notice]).to be_true
          expect(flash.now[:warning]).to be_true
          expect(response.code).to eq '302'
        end
      end
    end
  end

  describe 'PUT #update' do
    before do
      @event = FactoryGirl.create :event
    end

    context "when update and publish are successful" do

      subject { put :update, { continue_editing: true, id: @event.id, event: { event_instances_attributes: [[{}, { start_date: @event.event_instances.first.start_date, start_day: DateTime.now, start_time: Time.now, end_time: Time.now + 3600 }]] } } }

      it "flashes success" do
        current_user = @user
        User.any_instance.stub(:default_repository) { 'some value' }
        Content.any_instance.stub(:publish) { true }
        Event.any_instance.stub(:update_attributes) { true }

        subject

        expect(flash.now[:notice]).to be_true
      end
    end

    context "when update succeeds and publish fails" do

      subject { put :update, { create_new: true, id: @event.id, event: { event_instances_attributes: [[{}, { start_date: @event.event_instances.first.start_date }]] } } }

      it "flashes success with Publish failed message" do
        current_user = @user
        User.any_instance.stub(:default_repository) { 'some value' }
        Content.any_instance.stub(:publish) { false }

        subject

        expect(flash.now[:notice]).to be_true
        expect(flash.now[:warning]).to be_true
      end
    end

    context "when update fails" do

      subject { put :update, { id: @event.id, event: { event_instances_attributes: [[{}, { start_date: @event.event_instances.first.start_date }]] } } }

      it "renders edit page" do
        Event.any_instance.stub(:update_attributes) { false }
        expect(subject).to render_template 'edit'
      end
    end
  end

end
