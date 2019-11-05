# frozen_string_literal: true

require 'spec_helper'

describe ModerationMailer, type: :mailer do
  describe 'moderation_mailer email' do
    let(:content) { FactoryGirl.create :content, authors: 'test', authoremail: 'test@test.com' }
    let(:flagging_user) { FactoryGirl.create :user }
    let(:flag_issue) { 'Offensive' }

    subject { ModerationMailer.send_moderation_flag_v2(content, flag_issue, flagging_user).deliver_now }

    describe 'version 2' do
      it 'should send an email' do
        subject
        expect(ModerationMailer.deliveries.present?).to eq(true)
      end

      it { expect(subject.body).to include(flagging_user.name) }
      it { expect(subject.body).to include(flagging_user.email) }
      it { expect(subject.body).to include(content.authors) }
      it { expect(subject.body).to include(content.authoremail) }
      it { expect(subject.to[0]).to eq(Rails.configuration.subtext.emails.moderation) }

      describe 'content type edit link is correct' do
        context 'for regular content' do
          it { expect(subject.body).to include(edit_content_url(content)) }
        end

        context 'for market content' do
          let(:content) { FactoryGirl.create :content, :market_post }

          it { expect(subject.body).to include(edit_content_url(content)) }
        end

        context 'for event content' do
          let(:content) { FactoryGirl.create :content, :event }

          it { expect(subject.body).to include(edit_content_url(content)) }
        end
      end
    end
  end
end
