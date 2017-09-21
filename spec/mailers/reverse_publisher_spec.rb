require "rails_helper"
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
  describe 'mail_content_to_listservs' do
    let(:content) {
      FactoryGirl.create :content, authoremail: 'test@test.com', short_link: 'http://bit.ly/12345',
        content_category: FactoryGirl.create(:content_category, name: 'news')
    }
    let(:listservs) {
      FactoryGirl.create_list :vc_listserv, 2
    }
    let(:consumer_app) {FactoryGirl.create(:consumer_app)}

    before { allow(ConsumerApp).to receive(:current).and_return consumer_app }

    subject{ ReversePublisher.mail_content_to_listservs(content, listservs, consumer_app) }

    it 'is sent to both listserv reverse_publish_emails' do
      expect(subject.to).to include(*listservs.map(&:reverse_publish_email))
    end

    # this is testing the special construction of the consumer app URL 
    # for the content based on whether or not Thread.current[:consumer_app] is set

    it 'should include the ux2 content path for @content' do
      expect(subject.body.encoded).to include("http://bit.ly/12345")
    end

    describe 'Event', inline_jobs: true do
      let(:non_ugc_event) { FactoryGirl.create :event, skip_event_instance: true }
      let(:content) { non_ugc_event.content }

      before do
        FactoryGirl.create :event_instance, event: non_ugc_event, start_date: 2.weeks.ago, end_date: 1.week.ago, subtitle_override: 'interesting'
        FactoryGirl.create :event_instance, event: non_ugc_event, start_date: 1.days.from_now, end_date: 3.days.from_now, subtitle_override: 'go on'
        non_ugc_event.reload
        content.update_attribute(:short_link, 'http://bit.ly/12345')
      end

      it_behaves_like "non-ugc event without schedules" do
        let(:test_event) { non_ugc_event }
        let(:rp_email) { subject }
      end

      context 'with recurring schedules' do
        let(:multi_event) { FactoryGirl.create :event, skip_event_instance: true }
        let(:content) { multi_event.content }

        before do
          content.update_attribute(:short_link, 'http://bit.ly/12345')
        end

        let!(:schedule1) { FactoryGirl.create :schedule, event: multi_event, subtitle_override: 'no loco', recurrence: IceCube::Schedule.new(Time.zone.now + 1.hour, duration: 2.hours){ |s| s.add_recurrence_rule IceCube::Rule.daily.until(1.week.from_now) }.to_yaml }

        let!(:schedule2) { FactoryGirl.create :schedule, event: multi_event, subtitle_override: 'no loco 2', recurrence: IceCube::Schedule.new(Time.zone.now - 2.days, duration: 4.hours){ |s| s.add_recurrence_rule IceCube::Rule.weekly.until(4.weeks.from_now) }.to_yaml }

        it 'email should contain an event summary' do
          #schedules in this test must have recurrence
          multi_event.schedules.each do |schedule|
              subject.body.parts.each do |part|
                expect(part.to_s).to include(friendly_schedule_date(schedule)[0])
                expect(part.to_s).to include(friendly_schedule_date(schedule)[1])
              end
          end
        end
      end

      context ', with single ocuurrence schedules' do
        let(:ugc_single_event) { FactoryGirl.create :event, skip_event_instance: true }
        let(:content) { ugc_single_event.content }
        let(:schedule_starts) { Time.zone.now + 3.days }
        let!(:schedule) { FactoryGirl.create :schedule, event: ugc_single_event, subtitle_override: 'no loco 3', recurrence: IceCube::Schedule.new(schedule_starts, duration: 30.minutes){ |s| s.add_recurrence_rule IceCube::SingleOccurrenceRule.new(schedule_starts) }.to_yaml }

        it_behaves_like 'non-ugc event without schedules' do
          let(:test_event) { ugc_single_event }
          let(:rp_email) { subject }
        end
      end
    end
  end

end
