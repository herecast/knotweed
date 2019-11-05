# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentAlert do
  let(:org) { FactoryGirl.create :organization, name: 'Listserv' }
  let(:parent_content_owner) { FactoryGirl.create :user, receive_comment_alerts: true }
  let(:parent_content) { FactoryGirl.create :content, :talk, created_by: parent_content_owner }
  let(:comment1) { FactoryGirl.build :comment, content_id: parent_content.id }
  let(:no_alert_content_owner) { FactoryGirl.create :user, receive_comment_alerts: false }
  let(:no_alert_content) { FactoryGirl.create :content, :talk, created_by: no_alert_content_owner }
  let(:comment2) { FactoryGirl.create :comment, content_id: no_alert_content.id }
  let(:author_comment) { FactoryGirl.create :comment, created_by: parent_content_owner, content: no_owner_content }
  let(:no_owner_content) { FactoryGirl.create :content, created_by: nil }

  context 'when content is not a comment' do
    it 'does not send an email alert' do
      expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(parent_content)
      CommentAlert.call(parent_content)
    end
  end

  context 'when content is a comment' do
    it 'sends an email alert to the parent content creator' do
      mail = double
      expect(mail).to receive(:deliver_later)
      expect(CommentAlertMailer).to receive(:alert_parent_content_owner).with(comment1, parent_content).and_return(mail)
      CommentAlert.call(comment1)
    end

    context 'when user has receive_comment_alerts = false'  do
      it 'does not send an email to the parent content owner' do
        expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(comment2, no_alert_content)
        CommentAlert.call(comment2)
      end
    end

    context 'when the author is commenting on their own post' do
      it 'does not attempt to send an email' do
        expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(author_comment, parent_content)
        CommentAlert.call(author_comment)
      end
    end

    context 'when parent content does not have created_by' do
      it 'does not attempt to send an email' do
        expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(author_comment, no_owner_content)
        CommentAlert.call(no_owner_content)
      end
    end
  end
end
