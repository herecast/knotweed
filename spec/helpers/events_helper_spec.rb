require 'spec_helper' 

describe EventsHelper, type: :helper do
  before do
    @event = FactoryGirl.create :event
  end

  describe '#ux2_event_path' do

    it 'should return /events/#{event_instance_id}' do
      expect(helper.ux2_event_path(@event)).to eq("/events/#{@event.event_instances.first.id}")
    end
  end

  describe '#cost_label' do
    subject { helper.cost_label(@event) }

    context 'When cost and cost_type present;' do
      before do
        @event.cost = 9.99
        @event.cost_type = :donation
      end

      it { should eql 'donation - 9.99' }
    end

    context 'When cost, but no cost_type present;' do
      before do
        @event.cost = 9.99
        @event.cost_type = nil
      end

      it { should eql '9.99' }
    end

    context 'When no cost, but cost_type present;' do
      before do
        @event.cost = nil
        @event.cost_type = :free
      end

      it { should eql 'free' }
    end
  end

  describe '#event_search_field_value' do
    let(:key) { :a_key }
    subject { helper.event_search_field_value(key) }
    context 'params[:reset] is true' do
      before do
        params[:reset] = true
      end
      it { should be nil }
    end

    context 'session[:events_search] exists' do
      before do
        session[:events_search] = {:a_key => 'a_value'}
      end

      it 'returns session[:events_search][key]' do
        expect(subject).to eql "a_value"
      end
    end

    context 'params[:q] is present' do
      before do
        params[:q] = {:a_key => 'a_value'}
      end

      it 'returns params[:q][key]' do
        expect(subject).to eql 'a_value'
      end
    end
  end

  describe '#event_url_for_email' do
    subject { helper.event_url_for_email(@event) }
    let(:event_path) { ux2_event_path(@event) }
    let(:utm_string) { "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{event_path}" }

    context 'consumer_app set from request' do
      let(:consumer_app) { double(uri: 'http://my-uri.example') }
      before do
        Thread.current[:consumer_app] = consumer_app
      end

      it { should eql "#{consumer_app.uri}#{event_path}#{utm_string}" }
    end

    context 'consumer_app not set; @base_uri set from controller' do
      before do
        @base_uri = 'http://event.foo'
        Thread.current[:consumer_app] = nil
        @event.event_instances.first.id = 9999
      end

      it 'uses @base_uri, and first instance id to generate a url' do
        expect(subject).to eql "#{@base_uri}/events/9999#{utm_string}"
      end
    end

    context 'if not consumer_app, or @base_uri;' do
      before do 
        @base_uri = nil
        Thread.current[:consumer_app] = nil
      end

      it { should eql "http://www.dailyuv.com/events" }
    end
  end
end
