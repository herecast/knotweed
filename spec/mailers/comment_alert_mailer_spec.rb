# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentAlertMailer do
  describe '.alert_parent_content_owner' do
    let(:parent_owner) { FactoryGirl.create :user }
    let(:comment_owner) { FactoryGirl.create :user }
    let(:parent_content) { FactoryGirl.create :content, :talk, created_by: parent_owner }
    let(:comment) do
      FactoryGirl.create :comment, content: parent_content, created_by: comment_owner,
        raw_content: 'THIS IS UNIQUE COMMENT BLARGH'
    end

    subject { described_class.alert_parent_content_owner(comment, parent_content).deliver_now }

    it 'successfully delivers the email' do
      expect { subject }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end

    it 'contains creates the correct subject' do
      expect_any_instance_of(CommentAlertMailer).to receive(:mail).with(to: parent_content.created_by.email,
                                                                        from: 'HereCast <notifications@herecast.us>',
                                                                        subject: "#{comment.created_by.name} just commented on your post on HereCast").and_return(Mail::Message.new)
      subject
    end

    describe 'email content' do
      subject { described_class.alert_parent_content_owner(comment, parent_content) }

      it 'includes the time of the comment' do
        expect(subject.body).to include comment.created_at.strftime('%B %e at %l:%M%P')
      end

      it 'includes title as link to the parent content' do
        expect(subject.body).to include parent_content.title
      end

      it 'contains a mailto link that populates an email for to an admin to unsubscribe user' do
        expect(subject.body).to include "<a href=\"mailto:help@herecast.us?body=Please%20unsubscribe%20this%20user%20from%20future%20comment%20alerts%3A%20http%3A%2F%2F198.74.61.63%3A8002%2Fadmin%2Fusers%2F#{parent_owner.id}%2Fedit&amp;subject=Unsubscribe%20from%20comment%20alerts\">click here to unsubscribe.</a>"
      end

      context 'when comment_hidden: true' do
        subject { described_class.alert_parent_content_owner(comment, parent_content, true) }

        it 'contains comment text' do
          expect(subject.body).to include comment.sanitized_content
        end
      end

      context 'when comment_hidden: false' do
        subject { described_class.alert_parent_content_owner(comment, parent_content, false) }

        it 'does not contain comment text' do
          expect(subject.body).not_to include comment.sanitized_content
        end
      end

    end
  end
end
