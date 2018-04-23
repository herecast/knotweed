require 'rails_helper'

RSpec.describe ReindexAssociatedContentJob do

  describe 'with an organization' do
    let(:organization) { FactoryGirl.create :organization }

    subject {
      described_class.new.perform(organization)
    }

    context 'when organization owns content records' do
      let!(:contents) {
        FactoryGirl.create_list :content, 3, organization: organization, published: true
      }

      it 'calls #reindex on each of those content records' do
        indexed_content_ids = []
        allow_any_instance_of(Content).to receive(:reindex) do |receiver|
          indexed_content_ids << receiver.id
        end

        subject
        expect(indexed_content_ids).to match_array contents.map(&:id)
      end

      context 'other content records exist, not owned by org' do
        let!(:others) {
          FactoryGirl.create_list :content, 3, published: true
        }

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

    subject {
      described_class.new.perform(user)
    }

    context 'when a user owns content records' do
      let!(:contents) {
        FactoryGirl.create_list :content, 3, created_by: user, published: true
      }

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
      let!(:content) {
        FactoryGirl.create :content
      }
      let!(:comment) {
        FactoryGirl.create :content, :comment, created_by: user, parent_id: content.id
      }

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
      let!(:others) {
        FactoryGirl.create_list :content, 3, published: true
      }

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
