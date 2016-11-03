# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  listserv_id   :integer
#  community_ids :integer          default([]), is an Array
#  promotion_id  :integer
#  sponsored_by  :string
#  digest_query  :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  title         :string
#

require 'rails_helper'

RSpec.describe Campaign, type: :model do
  it{ is_expected.to have_db_column(:listserv_id).of_type(:integer) }
  it{ is_expected.to have_db_column(:community_ids).of_type(:integer).with_options(array: true) }
  it{ is_expected.to have_db_column(:promotion_id).of_type(:integer) }
  it{ is_expected.to have_db_column(:sponsored_by).of_type(:string) }
  it{ is_expected.to have_db_column(:digest_query).of_type(:text) }

  it{ is_expected.to belong_to(:listserv) }
  it{ is_expected.to belong_to(:promotion) }
  it{ is_expected.to have_db_column(:title).of_type(:string) }

  describe 'communities' do
    context 'assigned an array of locations' do
      let(:locations) { FactoryGirl.create_list :location, 3 }
      before do
        subject.communities = locations
      end

      it 'assigns community_ids equal to location ids' do
        expect(subject.community_ids).to eql locations.collect(&:id)
      end
    end

    context 'assigned nil' do
      before do
        subject.communities = nil
      end

      it 'assigns community_ids to an empty array' do
        expect(subject.community_ids).to eql []
      end
    end

    context 'when community_ids holds location ids' do
      let(:locations) { FactoryGirl.create_list :location, 3 }
      before do
        subject.community_ids = locations.collect(&:id)
      end

      it 'is equal to the locations' do
        expect(subject.communities.to_a.sort_by(&:id)).to eql locations.sort_by(&:id)
      end
    end
  end

  it 'validates at least one community' do
    subject.community_ids = []
    expect(subject).to_not be_valid
    expect(subject.errors).to include(:community_ids)

    subject.community_ids << FactoryGirl.create(:location).id
    subject.valid?
    expect(subject.errors).to_not include(:community_ids)
  end

  describe 'community overlap' do
    context 'when multiple campaigns exist for a listserv' do
      let(:locations) { FactoryGirl.create_list :location, 2 }
      let!(:campaign1) {
        FactoryGirl.create :campaign,
          communities: [locations.first]
      }
      let!(:campaign2) {
        FactoryGirl.create :campaign,
          listserv: campaign1.listserv,
          communities: [locations.last]
      }

      it 'validates that community can\'t be assigned to multiple campaigns' do
        expect(campaign1).to be_valid
        expect(campaign2).to be_valid

        campaign2.communities = [locations.first]

        expect(campaign2).to_not be_valid
        expect(campaign2.errors[:community_ids]).to include("cannot have community included in another campaign")
      end
    end
  end

end
