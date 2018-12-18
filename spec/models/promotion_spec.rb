# frozen_string_literal: true

# == Schema Information
#
# Table name: promotions
#
#  id              :bigint(8)        not null, primary key
#  banner          :string(255)
#  content_id      :bigint(8)
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :bigint(8)
#  promotable_type :string(255)
#  paid            :boolean          default(FALSE)
#  created_by_id   :integer
#  updated_by_id   :integer
#  share_platform  :string
#
# Indexes
#
#  idx_16765_index_promotions_on_content_id  (content_id)
#  idx_16765_index_promotions_on_created_by  (created_by)
#

require 'spec_helper'

describe Promotion, type: :model do
  before do
    @org = FactoryGirl.create(:organization)
    @content = FactoryGirl.create(:content)
  end

  after do
    FileUtils.rm_rf('./public/promotion')
  end

  include_examples 'Auditable', Promotion

  let(:valid_params) do
    {
      description: 'What a terrible promotion'
    }
  end

  subject do
    p = Promotion.create params
    p.organization = @org
    p.content = @content
    p.save
    p
  end

  context 'with valid params' do
    let (:params) { valid_params }
    it 'should be valid' do
      expect(subject).to be_valid
    end

    it 'should create a new promotion' do
      expect { subject }.to change { Promotion.count }.by(1)
    end
  end
end
