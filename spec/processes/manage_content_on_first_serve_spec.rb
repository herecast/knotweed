# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageContentOnFirstServe do
  RSpec::Matchers.define_negated_matcher :not_change, :change

  describe '::call', elasticsearch: true do
    before do
      @current_time = Time.current.to_s
    end

    context 'when first_served_at is nil' do
      before do
        @caster = FactoryGirl.create :caster
        @organization = FactoryGirl.create :organization
        @content = FactoryGirl.create :content,
                                      organization_id: @organization.id,
                                      created_by: @caster
        allow(SlackService).to receive(
          :send_published_content_notification
        ).and_return(true)
        allow(IntercomService).to receive(
          :send_published_content_event
        ).and_return(true)
        allow(FacebookService).to receive(
          :rescrape_url
        ).and_return(true)
      end

      subject do
        ManageContentOnFirstServe.call(
          content_ids: [@content.id],
          current_time: @current_time
        )
      end

      it "does narrow reindex on owning Organization" do
        expect_any_instance_of(Organization).to receive(
          :reindex
        ).with(:post_count_data)
        subject
      end

      context 'when content has no mc_campaign_id' do
        context 'when Caster has subscribers' do
          before do
            user = FactoryGirl.create :user
            @caster.caster_followers.create(
              user_id: user.id
            )
          end

          it 'calls to schedule Mailchimp post' do
            expect(BackgroundJob).to receive(:perform_later).with(
              'Outreach::SendOrganizationPostNotification',
              'call',
              @content
            )
            subject
          end
        end

        context 'when content Organization has no subscribers' do
          it 'does not call to schedule Mailchimp post' do
            expect(BackgroundJob).not_to receive(:perform_later)
            subject
          end
        end
      end

      context 'when content has mc_campaign_id' do
        context 'when content Organization has subscribers' do
          before do
            user = FactoryGirl.create :user
            @organization.organization_subscriptions.create(
              user_id: user.id
            )
            @content.update_attribute(:mc_campaign_id, '1234')
          end

          it 'does not call to schedule Mailchimp post' do
            expect(BackgroundJob).not_to receive(:perform_later)
            subject
          end
        end
      end
    end

    context 'when content not for Blog' do
      before do
        @content_one = FactoryGirl.create :content
        @content_two = FactoryGirl.create :content,
                                          first_served_at: Date.yesterday
        @draft_content = FactoryGirl.create :content,
                                            pubdate: nil
        @scheduled_content = FactoryGirl.create :content,
                                                pubdate: Date.tomorrow
        allow(SlackService).to receive(
          :send_published_content_notification
        ).and_return(true)
        allow(IntercomService).to receive(
          :send_published_content_event
        ).and_return(true)
        allow(FacebookService).to receive(
          :rescrape_url
        ).and_return(true)
      end

      subject do
        ManageContentOnFirstServe.call(
          content_ids: [@content_one.id, @content_two.id, @draft_content, @scheduled_content],
          current_time: @current_time
        )
      end

      it 'updates first_served_at for previously unserved content item' do
        expect { subject }.to change {
          @content_one.reload.first_served_at.to_s
        }.to(@current_time).and not_change {
          @content_two.reload.first_served_at
        }
      end

      it 'does not update draft content' do
        expect { subject }.not_to change {
          @draft_content.reload.first_served_at
        }
      end

      it 'does not update scheduled content' do
        expect { subject }.not_to change {
          @scheduled_content.reload.first_served_at
        }
      end

      context 'when PRODUCTION_MESSAGING_ENABLED is set to true' do
        before do
          allow(Figaro.env).to receive(:production_messaging_enabled).and_return('true')
          @news = FactoryGirl.create :content, :news
          @market = FactoryGirl.create :content, :market_post
        end

        subject do
          ManageContentOnFirstServe.call(
            content_ids: [@news.id],
            current_time: @current_time
          )
        end

        it 'pings Facebook service to scrape URL' do
          expect(FacebookService).to receive(:rescrape_url).with(@news)
          subject
        end

        context 'when content type is news' do
          it 'pings Intercom service' do
            expect(IntercomService).to receive(
              :send_published_content_event
            ).with(@news)
            subject
          end

          it 'pings Slack service' do
            expect(SlackService).to receive(
              :send_published_content_notification
            ).with(@news)
            subject
          end
        end

        context 'when content type is NOT news' do
          subject do
            ManageContentOnFirstServe.call(
              content_ids: [@market.id],
              current_time: @current_time
            )
          end

          it 'pings Facebook service to scrape URL' do
            expect(FacebookService).to receive(:rescrape_url).with(@market)
            subject
          end
        end
      end

      context 'when PRODUCTION_MESSAGING_ENABLED is NOT set or blank' do
        it 'does NOT ping Facebook service to rescrape' do
          expect(FacebookService).not_to receive(:rescrape_url)
          subject
        end

        it 'does NOT ping Intercom about published News posts' do
          expect(IntercomService).not_to receive(:send_published_content_event)
          subject
        end

        it 'does NOT ping Slack service about published News posts' do
          expect(SlackService).not_to receive(:send_published_content_notification)
          subject
        end
      end
    end

    context 'when Content Organization is a blog' do
      before do
        @campaign_id = 'nkjn23'
        @organization = FactoryGirl.create :organization,
                                           org_type: 'Blog',
                                           reminder_campaign_id: @campaign_id
        FactoryGirl.create :content,
                           organization_id: @organization.id,
                           pubdate: 1.day.ago
        @first_real_content = FactoryGirl.create :content,
                                                 first_served_at: nil,
                                                 organization_id: @organization.id
        allow(Outreach::ScheduleBloggerEmails).to receive(:call).and_return true
        allow(MailchimpService::UserOutreach).to receive(
          :get_campaign_status
        ).with(@campaign_id).and_return 'scheduled'
        allow(MailchimpService::UserOutreach).to receive(
          :delete_campaign
        ).with(@campaign_id).and_return true
      end

      context 'when content is first for the Org' do
        subject do
          ManageContentOnFirstServe.call(
            content_ids: [@first_real_content.id],
            current_time: @current_time
          )
        end

        it 'calls to create user hook campaign' do
          expect(Outreach::ScheduleBloggerEmails).to receive(:call).with(
            user: @first_real_content.created_by,
            action: 'first_blogger_post'
          )
          subject
        end

        it 'deletes Org reminder campaign' do
          expect(MailchimpService::UserOutreach).to receive(
            :delete_campaign
          ).with(@campaign_id)
          expect { subject }.to change {
            @organization.reload.reminder_campaign_id
          }.to nil
        end

        context 'when Mailchimp call fails in Production' do
          before do
            @error = Mailchimp::Error.new
            allow(Outreach::ScheduleBloggerEmails).to receive(:call).and_raise(
              @error
            )
            allow(SlackService).to receive(
              :send_new_blogger_error_alert
            ).and_return(true)
            allow(Figaro.env).to receive(
              :production_messaging_enabled
            ).and_return('true')
            allow(FacebookService).to receive(
              :rescrape_url
            ).and_return(true)
          end

          it 'sends Slack notification' do
            expect(SlackService).to receive(:send_new_blogger_error_alert).with(
              error: @error,
              user: @first_real_content.created_by,
              organization: @first_real_content.organization
            )
            subject
          end
        end
      end
    end
  end
end
