# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id         :bigint(8)        not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Comment, type: :model do
  before do
    @content = FactoryGirl.create :content, pubdate: 1.day.ago
    @comment = FactoryGirl.create :comment, content: @content
  end

  describe 'method missing override' do
    it 'should allow access to content attributes directly' do
      expect(@comment.title).to eq(@content.title)
      expect(@comment.authors).to eq(@content.authors)
      expect(@comment.pubdate).to eq(@content.pubdate)
    end

    it 'should retain normal method_missing behavior if not a content attribute' do
      expect { @comment.asdfdas }.to raise_error(NoMethodError)
    end
  end

  describe 'after_save' do
    it 'should also save the associated content record' do
      @content.title = 'Changed Title'
      @comment.save # should trigger @content.save callback
      expect(@content.reload.title).to eq 'Changed Title'
    end
  end

  describe 'after_create' do
    before do
      @parent = FactoryGirl.create :content, pubdate: 1.week.ago
      @user = FactoryGirl.create :admin
    end

    it 'should increase the counter comments' do
      @content.parent = @parent
      @content.save
      count = @parent.comment_count
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.comment_count).to eq(count + 1)
    end

    it 'should increase the counter commenters' do
      User.current = @user
      count = @parent.commenter_count
      @content = FactoryGirl.create :content
      @content.parent = @parent
      @content.save
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.commenter_count).to eq(count + 1)
    end

    it 'should not increase the counter commenters, if same user' do
      count = @parent.commenter_count
      @content = FactoryGirl.create :content, created_by: @user
      @content.parent = @parent
      @content.save

      @content = FactoryGirl.create :content, created_by: @user
      @content.parent = @parent
      @content.save
      FactoryGirl.create :comment, content: @content
      @parent.reload
      expect(@parent.commenter_count).to eq(count)
    end

    context 'when parent content is less than one week old' do
      subject do
        FactoryGirl.create :content, :comment,
                           parent_id: @content.id
      end

      it 'updates parent content latest_activity' do
        Timecop.freeze do
          expect { subject }.to change {
            @content.reload.latest_activity
          }
        end
      end

      context 'when parent content is an Event' do
        before do
          @event = FactoryGirl.create :content, :event,
                                      pubdate: 1.day.ago,
                                      latest_activity: 1.day.ago
        end

        subject do
          FactoryGirl.create :content, :comment,
                             parent_id: @event.id
        end

        it 'does not update latest_activity' do
          expect { subject }.not_to change {
            @event.reload.latest_activity
          }
        end
      end
    end

    context 'when parent content is less than one week old' do
      subject do
        FactoryGirl.create :content, :comment,
                           parent_id: @content.id
      end

      it 'updates parent content latest_activity' do
        Timecop.freeze(Time.current + 8.day) do
          expect { subject }.not_to change {
            @content.reload.latest_activity
          }
        end
      end
    end
  end

  describe '#decrease_comment_stats' do
    before do
      @user = FactoryGirl.create :user
      @parent_content = FactoryGirl.create :content
      @comment = FactoryGirl.create :comment,
                                    deleted_at: Date.yesterday
      @comment.content.update_attributes!(
        parent_id: @parent_content.id,
        created_by: @user
      )
    end

    context 'when deleted comment auther has only written one comment on article' do
      subject { @comment.decrease_comment_stats }

      it 'decreases parent comment_count and commenter_count' do
        expect { subject }.to change {
          @comment.parent.reload.comment_count
        }.by(-1).and change {
          @comment.parent.reload.commenter_count
        }.by(-1)
      end
    end

    context 'when deleted comment auther has written multiple comments on article' do
      before do
        @comment_two = FactoryGirl.create :comment
        @comment_two.content.update_attributes!(
          parent_id: @parent_content.id,
          created_by: @user
        )
      end

      subject { @comment.decrease_comment_stats }

      it 'decreases parent comment_count but not commenter_count' do
        expect { subject }.to change {
          @comment.parent.reload.comment_count
        }.by(-1).and change {
          @comment.parent.reload.commenter_count
        }.by(0)
      end
    end
  end
end
