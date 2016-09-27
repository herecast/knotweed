require 'rails_helper'

RSpec.describe ListservDigest, type: :model do
  it { is_expected.to have_db_column(:campaign_id).of_type(:string) }
  it { is_expected.to have_db_column(:sent_at).of_type(:datetime) }
  it { is_expected.to have_db_column(:listserv_content_ids).of_type(:string) }
  it { is_expected.to have_db_column(:content_ids).of_type(:string) }

  it { is_expected.to belong_to(:listserv) }

  it { is_expected.to respond_to :listserv_contents }
  it { is_expected.to respond_to :contents }

  describe '#contents' do
    context 'after assigned and persisted' do
      let!(:contents) { FactoryGirl.create_list :content, 3 }
      let!(:digest) { FactoryGirl.create :listserv_digest, contents: contents.reverse }

      it 'returns the contents in the same order' do
        reloaded_digest = described_class.find(digest.id)
        expect(reloaded_digest.contents.first).to eql contents.reverse.first
      end
    end
  end

end
