require 'spec_helper'

describe Api::V2::ContentsController do
  before do
    @repo = FactoryGirl.create :repository
  end

  describe 'GET similar_content' do
    before do
      @event = FactoryGirl.create :event
      @sim_content = FactoryGirl.create :content
      Content.any_instance.stub(:similar_content).with(@repo, 20).and_return([@sim_content])
    end

    subject { get :similar_content, format: :json,
        event_id: @event.id, repository: @repo.dsp_endpoint }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with relation of similar content' do
      subject
      assigns(:contents).should eq([@sim_content])
    end
  end

end
