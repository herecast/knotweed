# frozen_string_literal: true
# == Schema Information
#
# Table name: comments
#
#  id            :bigint(8)        not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  raw_content   :text
#  pubdate       :datetime
#  content_id    :bigint(8)
#  location_id   :bigint(8)
#  created_by_id :bigint(8)
#  updated_by_id :bigint(8)
#
# Indexes
#
#  index_comments_on_content_id     (content_id)
#  index_comments_on_created_by_id  (created_by_id)
#  index_comments_on_location_id    (location_id)
#  index_comments_on_updated_by_id  (updated_by_id)
#

require 'spec_helper'

describe Comment, type: :model do
  let(:content) { FactoryGirl.create :content, pubdate: 1.day.ago }
  let!(:comment) { FactoryGirl.create :comment, content: content }

  # this is normally called as an `after_create` callback but we are just testing
  # method functionality here
  describe '#increase_comment_stats' do
    subject { comment.increase_comment_stats }

    it 'should increase contents.comment_count' do
      expect{subject}.to change{ content.comment_count }.by(1)
    end

    describe 'when a new user comments' do
      let(:new_user) { FactoryGirl.create :user }
      before { comment.update created_by: new_user }

      it 'should increase contents.commenter_count' do
        expect{subject}.to change{ content.commenter_count }.by(1)
      end
    end

    describe 'when the same user comments' do
      let(:new_comment) { FactoryGirl.create :comment, content: content, created_by: comment.created_by }

      it 'should not increase contents.commenter_count' do
        expect{new_comment.increase_comment_stats}.not_to change{ content.commenter_count }
      end
    end

    describe 'when content is an event' do
      let(:event) { FactoryGirl.create :event, pubdate: 1.week.ago }
      let!(:comment) { FactoryGirl.create :comment, content: event.content }
      
      it 'should not update latest_activity' do
        expect{subject}.not_to change{ event.content.latest_activity }
      end
    end

    describe 'when content is less than a week old' do
      let(:content) { FactoryGirl.create :content, pubdate: 1.day.ago }

      it 'should update latest_activity' do
        expect{subject}.to change{ content.latest_activity }
      end
    end

    describe 'when content is older than 1 week' do
      let(:content) { FactoryGirl.create :content, pubdate: 2.weeks.ago }

      it 'should not update latest_activity' do
        expect{subject}.not_to change{ content.latest_activity }
      end
    end
  end

  describe '#decrease_comment_stats' do
    let(:content) { FactoryGirl.create :content }
    let!(:comment) { FactoryGirl.create :comment, content: content }

    subject { comment.decrease_comment_stats }

    it 'should reduce content.comment_count by 1' do
      expect{subject}.to change{ content.comment_count }.by(-1)
    end

    describe 'when the same user has other comments' do
      let(:user) { FactoryGirl.create :user }
      before do
        comment.update created_by: user
        User.current = comment.created_by # set created_by to same author as original comment
      end
      let(:new_comment) { FactoryGirl.create :comment, content: content }

      it 'should not reduce content.comment_count' do
        expect{new_comment.decrease_comment_stats}.not_to change{ content.comment_count }
      end
    end
  end

  describe 'after_commit', elasticsearch: true do
    let!(:content) { FactoryGirl.create :content }
    let!(:comment) { FactoryGirl.create :comment, content: content }

    it 'should reindex the related content' do
      expect(content).to receive(:reindex)
      comment.update raw_content: 'Just triggering a commit'
    end
  end
end
