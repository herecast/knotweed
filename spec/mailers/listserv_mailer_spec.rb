require "rails_helper"


RSpec.describe ListservMailer, type: :mailer do
  let(:body_html) { subject.body.parts.find {|p| p.content_type.match /html/}.body.raw_source }
  let(:body_text) { subject.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source }

  before(:each) do
    ENV.stub(:[]).with("LISTSERV_MARKETING_URL").and_return("http://listserv.dailyUV.com")
    ENV.stub(:[]).with("DEFAULT_CONSUMER_HOST").and_return("test.localhost")
  end

  shared_examples :has_curious_why_changed_when_not_user_test do
    let(:message) { "Curious why things changed?" }

    it 'has curious why changed message' do
      expect(body_html).to include(message)
      expect(body_text).to include(message)
    end

    it 'includes link to listserv marketing site' do
      expect(body_html).to include(ENV['LISTSERV_MARKETING_URL'])
      expect(body_text).to include(ENV['LISTSERV_MARKETING_URL'])
    end

    context 'when listserv-user-testing feature is active' do
      before do
        FactoryGirl.create(:feature,
          name: 'listserv-user-testing',
          active: true
        )
      end

      it 'does not have curious why changed message' do
        expect(body_html).to_not include(message)
        expect(body_text).to_not include(message)
      end

      it 'does not include link to listserv marketing site' do
        expect(body_html).to_not include(ENV['LISTSERV_MARKETING_URL'])
        expect(body_text).to_not include(ENV['LISTSERV_MARKETING_URL'])
      end
    end
  end

  shared_examples :has_unsubscribe_with_user_test_changes do
    let(:unsub_wording) {
      /#{Regexp.escape("unsubscribe from")}\s+#{Regexp.escape(subscription.listserv.name)}/i
    }

    let(:unsub_url) {
      "http://#{ENV['DEFAULT_CONSUMER_HOST']}/lists/#{subscription.key}/manage"
    }

    it 'has unsubscribe link' do
      expect(body_html).to match(unsub_wording)
      expect(body_text).to match(unsub_wording)

      expect(body_html).to include(unsub_url)
      expect(body_text).to include(unsub_url)
    end

    context 'when listserv-user-testing feature is active' do
      before do
        FactoryGirl.create(:feature,
          name: 'listserv-user-testing',
          active: true
        )
      end

    let(:unsub_wording) {
      /#{Regexp.escape("unsubscribe from")}\s+#{Regexp.escape("this test")}/i
    }

      it 'has unsubscribe link with test wording' do
        expect(body_html).to match(unsub_wording)
        expect(body_text).to match(unsub_wording)

        expect(body_html).to include(unsub_url)
        expect(body_text).to include(unsub_url)
      end
    end
  end

  describe '#subscription_verification' do
    let(:subscription) { FactoryGirl.create :subscription, email: 'test@example.org' }
    subject { ListservMailer.subscription_verification(subscription) }

    it 'is sent to subscription#email' do
      expect(subject.to).to eql [subscription.email]
    end

    it 'includes confirmation link' do
      expect(body_html).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/lists/#{subscription.key}/subscribe")
      expect(body_text).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/lists/#{subscription.key}/subscribe")
    end

    it 'includes list name' do
      expect(body_html).to include(subscription.listserv.name)
      expect(body_text).to include(subscription.listserv.name)
    end

    include_examples :has_curious_why_changed_when_not_user_test
  end


  describe '#existing_subscription' do
    let(:listserv) { FactoryGirl.create :listserv, unsubscribe_email: 'unsub.me@list.org' }
    let(:subscription) { FactoryGirl.create :subscription, email: 'test@example.org', listserv: listserv }

    subject { ListservMailer.existing_subscription(subscription) }

    it 'is sent to subscription#email' do
      expect(subject.to).to eql [subscription.email]
    end

    it 'includes list name' do
      expect(body_html).to include(listserv.name)
      expect(body_text).to include(listserv.name)
    end

    it 'includes account subscriptions link' do
      expect(body_html).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/account/subscriptions")
      expect(body_text).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/account/subscriptions")
    end

    include_examples :has_curious_why_changed_when_not_user_test
  end


  describe '#posting_verification' do
    let(:subscription) {
      FactoryGirl.create :subscription,
        :subscribed
    }
    let(:listserv_content) {
      FactoryGirl.create :listserv_content,
        sender_email: subscription.email,
        subscription: subscription,
        listserv: subscription.listserv

    }
    subject { ListservMailer.posting_verification(listserv_content) }

    it 'is sent to listserv_content#sender_email' do
      expect(subject.to).to eql [listserv_content.sender_email]
    end

    it 'includes enhance link' do
      expect(body_html).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/lists/posts/#{listserv_content.key}")
      expect(body_text).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/lists/posts/#{listserv_content.key}")
    end

    it 'includes verify only link' do
      expect(body_html).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/api/v3/listserv_contents/#{listserv_content.key}/verify")
      expect(body_text).to include("http://#{ENV['DEFAULT_CONSUMER_HOST']}/api/v3/listserv_contents/#{listserv_content.key}/verify")
    end

    include_examples :has_curious_why_changed_when_not_user_test
    include_examples :has_unsubscribe_with_user_test_changes

    it 'includes list name' do
      expect(body_html).to include(listserv_content.listserv.name)
      expect(body_text).to include(listserv_content.listserv.name)
    end

    context 'when user is unsubscribed' do
      before do
        listserv_content.subscription.unsubscribed_at = Time.zone.now
        listserv_content.save
      end
      it 'does not display unsubscribe link' do
        expect(body_html).to_not include("UNSUBSCRIBE FROM") 
      end
    end
  end

  describe '#subscriber_blacklisted' do
    let(:listserv) { FactoryGirl.create :listserv, admin_email: 'admin@gmail.com' }
    let(:subscription) { FactoryGirl.create :subscription, listserv: listserv }
    subject { ListservMailer.subscriber_blacklisted(subscription) }

    it 'is sent when a subscriber is blacklisted' do
      expect(subject.subject).to eq "You've been blocked from posting to the #{subscription.listserv.name}"
    end

    it 'displays "Sorry!" in the title' do
      expect(body_html).to include('Sorry!')
      expect(body_text).to include('Sorry!')
    end

    it 'dispalys the admins email address' do
      expect(body_html).to include('mailto:admin@gmail.com')
      expect(body_text).to include('admin@gmail.com')
    end
  end
end
