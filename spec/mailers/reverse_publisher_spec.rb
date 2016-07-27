require "spec_helper"
include EventsHelper

shared_examples "non-ugc event without schedules" do
  it 'email should contain each event_instance dates in the email' do
    test_event.event_instances.each do |event_instance|
      rp_email.body.parts.each do |part|
        expect(part.to_s).to include(event_instance_display(event_instance))
      end
    end
  end
end

describe ReversePublisher, :type => :mailer do
  before do
    @news_cat = FactoryGirl.create :content_category, name: 'news'
    @content = FactoryGirl.create :content, authoremail: 'test@test.com', 
      content_category: @news_cat
    @listserv = FactoryGirl.create :listserv
  end

  describe 'after_create PromotionListserv object' do
    before do
      PromotionListserv.create_from_content(@content, @listserv)
      ReversePublisher.deliveries.each do |eml|
        # reverse publish email has this header set, confirmation email does not.
        if eml['X-Original-Content-Id'].present?
          @rp_email = eml
        else
          @conf_email = eml
        end
      end
    end

    it 'should send a confirmation email to the user' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@conf_email.to).to include(@content.authoremail)
    end

    it 'should send the reverse publish email to the listserv' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@rp_email.to).to include(@listserv.reverse_publish_email)
    end
  end

  describe 'when sending to multiple listservs' do
    before do
      @listserv2 = FactoryGirl.create :listserv
      PromotionListserv.create_multiple_from_content(@content, [@listserv.id, @listserv2.id])
      @rp_email = ReversePublisher.deliveries.select{ |eml| eml['X-Original-Content-Id'].present? }.first
    end

    it 'should only generate one reverse publish email' do
      expect(ReversePublisher.deliveries.count).to eq(2)
      expect(@rp_email.to).to include(@listserv.reverse_publish_email)
      expect(@rp_email.to).to include(@listserv2.reverse_publish_email)
    end
  end

  # this is testing the special construction of the consumer app URL 
  # for the content based on whether or not Thread.current[:consumer_app] is set
  describe 'ux2 content links' do
    let(:consumer_app) {FactoryGirl.create(:consumer_app)}
    before { allow(ConsumerApp).to receive(:current).and_return consumer_app }

    it 'should include the ux2 content path for @content' do
      @listserv.send_content_to_listserv(@content, consumer_app)
      # only the reverse publish email has this header, so use that to select it
      rp_email = ReversePublisher.deliveries.select{ |e| e['X-Original-Content-Id'].present? }.first
      expect(rp_email.body.encoded).to include("#{consumer_app.uri}/news/#{@content.id}")
    end
  end

  describe 'Event' do
    let(:listserv) { FactoryGirl.create :listserv }
    let(:non_ugc_event) { FactoryGirl.create :event, skip_event_instance: true }

    before do
      FactoryGirl.create :event_instance, event: non_ugc_event, start_date: 2.weeks.ago, end_date: 1.week.ago, subtitle_override: 'interesting'
      FactoryGirl.create :event_instance, event: non_ugc_event, start_date: 1.days.from_now, end_date: 3.days.from_now, subtitle_override: 'go on'
      PromotionListserv.create_from_content(non_ugc_event.content, listserv)
      @rp_email = ReversePublisher.deliveries.select{ |eml| eml['X-Original-Content-Id'].present? }.first
    end
    
    it_behaves_like "non-ugc event without schedules" do
      let(:test_event) { non_ugc_event }
      let(:rp_email) { @rp_email }
    end
    
    context 'with recurring schedules' do
      let(:multi_event) { FactoryGirl.create :event, skip_event_instance: true }

      let!(:schedule1) { FactoryGirl.create :schedule, event: multi_event, subtitle_override: 'no loco', recurrence: IceCube::Schedule.new(Time.zone.now + 1.hour, duration: 2.hours){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(1.week.from_now) }.to_yaml }

      let!(:schedule2) { FactoryGirl.create :schedule, event: multi_event, subtitle_override: 'no loco 2', recurrence: IceCube::Schedule.new(Time.zone.now - 2.days, duration: 4.hours){ |s| s.add_recurrence_rule IceCube::Rule.weekly.until(4.weeks.from_now) }.to_yaml }


      before do
        PromotionListserv.create_from_content(multi_event.content, listserv)
        @rp_email = ReversePublisher.deliveries.select{ |eml| eml['X-Original-Content-Id'].present? }.second #the second email in the queue
      end
      
      it 'email should contain an event summary' do
        #schedules in this test must have recurrence
        multi_event.schedules.each do |schedule|
            @rp_email.body.parts.each do |part|
              expect(part.to_s).to include(friendly_schedule_date(schedule)[0])
              expect(part.to_s).to include(friendly_schedule_date(schedule)[1])
            end
        end
      end   
    end

    context ', with single ocuurrence schedules' do
      let(:ugc_single_event) { FactoryGirl.create :event, skip_event_instance: true }
      let(:schedule_starts) { Time.zone.now + 3.days }
      let!(:schedule) { FactoryGirl.create :schedule, event: ugc_single_event, subtitle_override: 'no loco 3', recurrence: IceCube::Schedule.new(schedule_starts, duration: 30.minutes){ |s| s.add_recurrence_rule IceCube::SingleOccurrenceRule.new(schedule_starts) }.to_yaml }

      before do
        PromotionListserv.create_from_content(ugc_single_event.content, listserv)
        @rp_email = ReversePublisher.deliveries.select{ |eml| eml['X-Original-Content-Id'].present? }.second #the second email in the queue
      end
      it_behaves_like 'non-ugc event without schedules' do
        let(:test_event) { ugc_single_event }
        let(:rp_email) { @rp_email }
      end
    end
  end

end
