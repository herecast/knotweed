require 'rails_helper'

RSpec.describe ReindexOrganizationContentJob do
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
