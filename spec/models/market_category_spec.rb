#== Schema Information
#
# Table name: market_categories
# 
# id                  :integer
# name                :string
# query               :string
# category_image      :string
# detail_page_banner  :string
# featured            :boolean    default(FALSE)
# trending            :boolean    default(FALSE)
# created_at          :datetime
# updated_at          :datetime
#
require 'rails_helper'

RSpec.describe MarketCategory, type: :model do
  it { is_expected.to have_db_column(:name) }
  it { is_expected.to have_db_column(:query) }
  it { is_expected.to have_db_column(:category_image) }
  it { is_expected.to have_db_column(:detail_page_banner) }
  it { is_expected.to have_db_column(:featured) }
  it { is_expected.to have_db_column(:trending) }

  it { is_expected.to validate_presence_of(:name) }

  describe '#not_featured_and_trending' do

    context 'invalid' do
      before do
        @market_category = FactoryGirl.build :market_category, featured: true, trending: true
        @market_category.valid?
      end

      it 'is not valid with featured and trending true' do
        expect(@market_category.errors).not_to be_nil
      end

      it 'returns the correct error message' do
        expect(@market_category.errors.messages.first).to eq [:base, ['Cannot Be Featured AND Trending']]
      end
    end

    context 'valid' do
      before do
        @market_category = FactoryGirl.build :market_category, featured: true
        @market_category.valid?
      end

      it 'is valid' do
        expect(@market_category.errors.messages.count).to eq 0
      end
    end

  end

  describe '#trending_limit' do
    before do
      FactoryGirl.create_list :market_category, 3, trending: true
      @market_category = FactoryGirl.build :market_category, trending: true
      @market_category.valid?
    end

    it 'does not allow more than 3 cateories to be trending' do
      expect(@market_category.errors.full_messages).to eq ['Trending can only be true for 3 categories']
    end

    it 'is only called when trending field is changed to true' do
      @market_category.trending = false
      @market_category.valid?
      expect(@market_category.errors.count).to eq 0
      @market_category.trending = true
      @market_category.valid?
      expect(@market_category.errors.count).to eq 1
    end
  end

  describe '#featured_limit' do
    before do
      FactoryGirl.create_list :market_category, 6, featured: true
      @market_category = FactoryGirl.build :market_category, featured: true
      @market_category.valid?
    end

    it 'does not allow more than 6 catories to be featured' do
      expect(@market_category.errors.full_messages).to eq ['Featured can only be true for 6 categories']
    end

    it 'is only called when featured field is changed to true' do
      @market_category.featured = false
      @market_category.valid?
      expect(@market_category.errors.count).to eq 0
      @market_category.featured = true
      @market_category.valid?
      expect(@market_category.errors.count).to eq 1
    end
  end

  describe '.default_search_options' do
    before do
      @content_category = FactoryGirl.create :content_category, name: 'market'
    end

    it 'retuns a hash of default search options for search preview' do
      default_search_options = MarketCategory.default_search_options
      expect(default_search_options).to have_key(:order)
      expect(default_search_options).to have_key(:where)
      expect(default_search_options[:where]).to have_key(:pubdate)
      expect(default_search_options[:where]).to have_key(:root_content_category_id)
      expect(default_search_options.class).to eq Hash
    end
  end
end
