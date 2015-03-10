require 'spec_helper'

describe EventsController, :type => :controller  do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'Features Filter' do
    before do
      # setup the search query hash
      @q = {event_content_id_in:  "", event_content_title_cont: "", event_content_pubdate_gteq: "", event_content_pubdate_lteq: "",
           event_content_source_id_in: [""], event_content_authors_cont: "", start_date_gteq: "", start_date_lteq: "",
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