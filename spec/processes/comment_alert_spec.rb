require 'rails_helper'

RSpec.describe CommentAlert do
  let(:org) { FactoryGirl.create :organization, name: 'Listserv' }
  let(:parent_content_owner) { FactoryGirl.create :user, receive_comment_alerts: true }
  let(:parent_content) { FactoryGirl.create :content, :talk, created_by: parent_content_owner}
  let(:listserv_parent_content) { FactoryGirl.create :content, organization_id: org.id, created_by: parent_content_owner }
  let(:comment1) { FactoryGirl.build :content, :talk, parent_id: parent_content.id }
  let(:no_alert_content_owner) { FactoryGirl.create :user, receive_comment_alerts: false }
  let(:no_alert_content) { FactoryGirl.create :content, :talk, created_by: no_alert_content_owner }
  let(:comment2) { FactoryGirl.create :content, :talk, parent_id: no_alert_content.id }
  let(:listserv_comment) { FactoryGirl.create :content, :talk, parent_id: listserv_parent_content.id }
  let(:author_comment) { FactoryGirl.create :content, :talk, created_by: parent_content_owner }

  subject { described_class.call(comment, parent_content)}

  context 'when content is not a comment' do
    it 'does not send an email alert' do
      expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(parent_content)
      CommentAlert.call(parent_content)
    end
  end

  context 'when content is a comment' do
    it 'sends an email alert to the parent content creator' do
      mail = double()
      expect(mail).to receive(:deliver_later)
      expect(CommentAlertMailer).to receive(:alert_parent_content_owner).with(comment1, parent_content).and_return(mail)
      CommentAlert.call(comment1)
    end

    context 'when user has receive_comment_alerts = false' do
      it 'does not send an email to the parent content owner' do
        expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(comment2, no_alert_content)
        CommentAlert.call(comment2)
      end
    end

    context 'when the parent content is a Listserv item' do
      it 'does not attempt to send an email' do
        expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(listserv_comment, parent_content)
        CommentAlert.call(listserv_comment)
      end
    end

    context 'when the author is commenting on their own post' do
      it 'does not attempt to send an email' do
         expect(CommentAlertMailer).to_not receive(:alert_parent_content_owner).with(author_comment, parent_content)
         CommentAlert.call(author_comment)
      end
    end
    
  end
end
