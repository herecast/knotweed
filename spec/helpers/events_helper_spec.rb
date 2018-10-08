require 'spec_helper' 

describe EventsHelper, type: :helper do
  before do
    @event = FactoryGirl.create :event
  end

  describe '#cost_label' do
    subject { helper.cost_label(@event) }

    context 'When cost and cost_type present;' do
      before do
        @event.cost = 9.99
        @event.cost_type = :donation
      end

      it { is_expected.to eql 'donation - 9.99' }
    end

    context 'When cost, but no cost_type present;' do
      before do
        @event.cost = 9.99
        @event.cost_type = nil
      end

      it { is_expected.to eql '9.99' }
    end

    context 'When no cost, but cost_type present;' do
      before do
        @event.cost = nil
        @event.cost_type = :free
      end

      it { is_expected.to eql 'free' }
    end
  end

  describe '#event_search_field_value' do
    let(:key) { :a_key }
    subject { helper.event_search_field_value(key) }
    context 'params[:reset] is true' do
      before do
        params[:reset] = true
      end
      it { is_expected.to be nil }
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

  describe 'friendly_schedule_date' do
    
    let(:start_time) { Chronic.parse("2 days from now at 1pm") }
    let(:duration) { 1.hours }
    let(:end_date) { Chronic.parse("30 days from now") }
    let(:subtitle) { "tetly" }

    subject { friendly_schedule_date(@schedule) }
    
    before do
      @schedule =  FactoryGirl.create :schedule, subtitle_override: subtitle, recurrence: IceCube::Schedule.new(start_time, duration: duration){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(end_date) }.to_yaml 
    end

    it "should include a string version of the schedule" do
      expect(subject[1]).to eq "Repeats " + @schedule.schedule.to_s
    end

    context "when event starts in the past and ends in the past" do
      let(:start_time) { Chronic.parse("3 months ago at 1pm") }
      let(:duration) { 3.hours }
      let(:end_date) { Chronic.parse("5 days ago") }

      it "returns empty strings" do
        expect(subject[0]).to eq ""
        expect(subject[1]).to eq ""
      end
    end

    context "when event starts in the future and ends in the future" do
      it "returns the full date" do
        expect(subject[0]).to eq start_time.strftime("%b %-d, %Y") +  "  " + start_time.strftime("%-l:%M %P") + " - " + (start_time+duration).strftime("%-l:%M %P") + " - " + subtitle
      end
    end

    context "when event starts in the past and ends in the future" do
      let(:start_time) { Chronic.parse("last week monday at 10am") }
      let(:end_date) { Chronic.parse("next week saturday") }
       
      it "returns the next occurrence date as event date" do
        Timecop.freeze(Chronic.parse("11am")) do
          expect(subject[0]).to eq Chronic.parse("tomorrow at 10am").strftime("%b %-d, %Y") +  "  " + start_time.strftime("%-l:%M %P") + " - " + (start_time+duration).strftime("%-l:%M %P") + " - " + subtitle
        end
      end
    end
  end
end
