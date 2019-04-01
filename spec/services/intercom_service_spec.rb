# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntercomService do
  subject { IntercomService }

  it { is_expected.to respond_to(:send_published_content_event) }

  describe '#send_published_content_event', freeze_time: true do
    let(:content) { FactoryGirl.create :content }
    let(:intercom_client) { double('client') }
    let(:intercom_events) { double('events') }

    subject { IntercomService.send_published_content_event(content) }

    before do
      allow(Intercom::Client).to receive(:new).with(any_args).and_return(intercom_client)
      allow(intercom_client).to receive(:events).and_return(intercom_events)
    end

    it 'should call `Intercom::Client#events.create`' do
      expect(intercom_events).to receive(:create).with(
        event_name: 'published-content',
        email: content.created_by.email,
        created_at: Time.current.to_i,
        metadata: {
          "organization_name": content.organization.name,
          "number_of_published_posts": 0,
          "post_title": content.title
        }
      )
      subject
    end
  end
end
