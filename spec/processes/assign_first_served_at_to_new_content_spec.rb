require 'rails_helper'

RSpec.describe AssignFirstServedAtToNewContent do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  describe '::call' do
    before do
      @content_one = FactoryGirl.create :content
      @content_two = FactoryGirl.create :content,
        first_served_at: Date.yesterday
      @current_time = Time.current.to_s
      allow(SlackService).to receive(
        :send_published_content_notification
      ).and_return(true)
      allow(IntercomService).to receive(
        :send_published_content_event
      ).and_return(true)
      allow(IntercomService).to receive(
        :send_published_storyteller_content_alert
      ).and_return(true)
      allow(SlackService).to receive(
        :send_storyteller_post_notification
      ).and_return(true)
    end

    subject do
      AssignFirstServedAtToNewContent.call(
        content_ids: [@content_one.id, @content_two.id],
        current_time: @current_time
      )
    end

    it "updates first_served_at for previously unserved content item" do
      expect{ subject }.to change{
        @content_one.reload.first_served_at.to_s
      }.to(@current_time).and not_change{
        @content_two.reload.first_served_at
      }
    end

    context "when PRODUCTION_MESSAGING_ENABLED is set to true" do
      before do
        ENV['PRODUCTION_MESSAGING_ENABLED'] = 'true'
        @news = FactoryGirl.create :content, :news
        @market = FactoryGirl.create :content, :market_post
      end

      subject do
        AssignFirstServedAtToNewContent.call(
          content_ids: [@news.id],
          current_time: @current_time
        )
      end

      context "when content type is news" do
        it "pings Intercom service" do
          expect(IntercomService).to receive(
            :send_published_content_event
          ).with(@news)
          subject
        end

        it "pings Slack service" do
          expect(SlackService).to receive(
            :send_published_content_notification
          ).with(@news)
          subject
        end

        context "when created_by User is NOT Storyteller" do
          it "does NOT make Storyteller call to IntercomService" do
            expect(IntercomService).not_to receive(:send_published_storyteller_content_alert)
            subject
          end
        end
      end

      context "when content type is NOT news" do
        subject do
          AssignFirstServedAtToNewContent.call(
            content_ids: [@market.id],
            current_time: @current_time
          )
        end

        it "does NOT ping Intercom service" do
          expect(IntercomService).not_to receive(:send_published_content_event)
          subject
        end

        it "does NOT ping Slack service" do
          expect(SlackService).not_to receive(:send_published_content_notification)
          subject
        end
      end

      context "when created_by User is Storyteller" do
        before do
          @user = FactoryGirl.create :user
          @user.add_role(:storyteller)
          @news = FactoryGirl.create :content, :news, first_served_at: nil
          @old_news = FactoryGirl.create :content, :news, first_served_at: Date.yesterday
          @event = FactoryGirl.create :content, :event, first_served_at: nil
          @market_post = FactoryGirl.create :content, :market_post, first_served_at: nil
          @talk = FactoryGirl.create :content, :talk, first_served_at: nil
          @contents = [@news, @old_news, @event, @market_post, @talk]
          @contents.each { |c| c.update_attributes(created_by: @user) }
        end

        subject { AssignFirstServedAtToNewContent.call(content_ids: @contents.map(&:id), current_time: Time.current.to_s) }

        it "calls to Intercom service for new posts" do
          expect(IntercomService).to receive(
            :send_published_storyteller_content_alert
          ).exactly(4).times
          subject
        end

        it "calls to Slack service for new posts" do
          expect(SlackService).to receive(
            :send_storyteller_post_notification
          ).exactly(4).times
          subject
        end
      end
    end

    context "when PRODUCTION_MESSAGING_ENABLED is NOT set or blank" do
      it "does NOT ping Intercom about published News posts" do
        expect(IntercomService).not_to receive(:send_published_content_event)
        subject
      end

      it "does NOT ping Intercom about storytellers" do
        expect(IntercomService).not_to receive(:send_published_storyteller_content_alert)
        subject
      end

      it "does NOT ping Slack service about published News posts" do
        expect(SlackService).not_to receive(:send_published_content_notification)
        subject
      end

      it "does NOT ping Slack service about storytellers" do
        expect(SlackService).not_to receive(:send_storyteller_post_notification)
      end
    end
  end
end