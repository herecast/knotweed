require 'spec_helper' 

describe ContentsHelper, type: :helper do
  describe '#ux2_content_path' do
    before do
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @tott_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
      @news_cat = FactoryGirl.create :content_category, name: 'news'
    end

    it 'should return /#{cat_name}/#{content_id} for any non-talk category' do
      market = FactoryGirl.create :content, content_category: @market_cat
      expect(helper.ux2_content_path(market)).to eq("/market/#{market.id}")
      news = FactoryGirl.create :content, content_category: @news_cat
      expect(helper.ux2_content_path(news)).to eq("/news/#{news.id}")
    end

    it 'should return /talk/#{content_id} for tott category' do
      tott = FactoryGirl.create :content, content_category: @tott_cat
      expect(helper.ux2_content_path(tott)).to eq("/talk/#{tott.id}")
    end

  end
end

