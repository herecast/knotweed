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

  describe '#search_field_value' do
    let(:key) { :a_key }
    subject { helper.search_field_value(key) }

    context 'params[:reset]' do
      it { is_expected.to be nil }
    end

    context 'session[:contents_search]' do
      before do
        session[:contents_search] = {key => 'a_value'}
      end

      it 'returns session[:contents_search][key]' do
        expect(subject).to eql 'a_value'
      end
    end

    context 'params[:q]' do
      before do
        params[:q] = { key => 'a_value1' }
      end

      it 'returns params[:q][key]' do
        expect(subject).to eql 'a_value1'
      end
    end
  end

  describe '#remove_list_from_title' do
    context 'When title has [bracket content]' do
      subject{ helper.remove_list_from_title("My Title [in brackets]") }

      it 'removes [bracket content]' do
        expect(subject).to_not include('[in brackets]')
      end
    end
  end

  describe '#can_be_listserv_promoted' do
    let(:content) { Content.new }
    before do
      content.authors = "Tim Timmons"
      content.authoremail = 'test@maildrop.cc'
      content.title = 'the title'
    end
    subject { helper.can_be_listserv_promoted(content) }

    context 'When authors, authoremail, and title' do
      it { is_expected.to be true }
    end

    context 'When authors empty' do
      before do
        content.authors = nil
      end

      it { is_expected.to be false }
    end

    context 'When authoremail blank' do
      before do
        content.authoremail = ""
      end

      it { is_expected.to be false }
    end

    context 'When title blank' do
      before do
        content.title = ""
      end

      it { is_expected.to be false }
    end
  end

  describe '#content_url_for_email' do
    let(:content) { FactoryGirl.create :content }
    subject { helper.content_url_for_email(content) }
    let(:content_path) { ux2_content_path(content) }
    let(:utm_string) { "?utm_medium=email&utm_source=rev-pub&utm_campaign=20151201&utm_content=#{content_path}" }

    context 'consumer_app set from request' do
      let(:consumer_app) { double(uri: 'http://my-uri.example') }

      it 'is generates url based on consumer_app uri' do
        Thread.new do
          Thread.current[:consumer_app] = consumer_app
          expect(subject).to eql "#{consumer_app.uri}#{content_path}#{utm_string}"
        end.join
      end
    end

    context 'consumer_app not set; @base_uri set from controller' do
      before do
        @base_uri = 'http://event.foo'
      end

      it 'uses @base_uri' do
        Thread.new do
          Thread.current[:consumer_app] = nil
          expect(subject).to eql "#{@base_uri}/contents/#{content.id}#{utm_string}"
        end.join
      end
    end

    context 'if not consumer_app, or @base_uri;' do
      before do
        @base_uri = nil
      end
      it 'Uses a default url' do
        Thread.new do
          Thread.current[:consumer_app] = nil
          expect(subject).to eql "http://www.dailyuv.com/contents/#{content.id}"
        end.join
      end
    end
  end
end

