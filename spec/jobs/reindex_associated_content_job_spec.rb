# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReindexAssociatedContentJob do
  describe 'with an organization' do
    let(:organization) { FactoryGirl.create :organization }

    subject do
      described_class.new.perform(organization)
    end

    context 'when organization owns content records' do
      let!(:contents) do
        FactoryGirl.create_list :content, 3, organization: organization
      end

      it 'calls #reindex on each of those content records' do
        indexed_content_ids = []
        allow_any_instance_of(Content).to receive(:reindex) do |receiver|
          indexed_content_ids << receiver.id
        end

        subject
        expect(indexed_content_ids).to match_array contents.map(&:id)
      end

      context 'other content records exist, not owned by org' do
        let!(:others) do
          FactoryGirl.create_list :content, 3
        end

        it 'does not reindex those records' do
          indexed_content_ids = []
          allow_any_instance_of(Content).to receive(:reindex) do |receiver|
            indexed_content_ids << receiver.id
          end

          subject
          expect(indexed_content_ids).to_not include *others.map(&:id)
        end
      end
    end
  end

  describe 'with an user' do
    let(:user) { FactoryGirl.create :user }

    subject do
      described_class.new.perform(user)
    end

    context 'when a user owns content records' do
      let!(:contents) do
        FactoryGirl.create_list :content, 3, created_by: user
      end

      it 'calls #reindex on each of those content records' do
        indexed_content_ids = []
        allow_any_instance_of(Content).to receive(:reindex) do |receiver|
          indexed_content_ids << receiver.id
        end

        subject
        expect(indexed_content_ids).to match_array contents.map(&:id)
      end
    end

    context 'when a user owns content records which are comments' do
      let!(:content) do
        FactoryGirl.create :content
      end
      let!(:comment) do
        FactoryGirl.create :content, :comment, created_by: user, parent_id: content.id
      end

      it 'the parent is reindexed' do
        indexed_content_ids = []
        allow_any_instance_of(Content).to receive(:reindex) do |receiver|
          indexed_content_ids << receiver.id
        end

        subject
        expect(indexed_content_ids).to match_array [content.id]
      end
    end

    context 'other content records exist, not owned by org' do
      let!(:others) do
        FactoryGirl.create_list :content, 3
      end

      it 'does not reindex those records' do
        indexed_content_ids = []
        allow_any_instance_of(Content).to receive(:reindex) do |receiver|
          indexed_content_ids << receiver.id
        end

        subject
        expect(indexed_content_ids).to_not include *others.map(&:id)
      end
    end
  end
end
