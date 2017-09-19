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
      tott = FactoryGirl.create :content, :located, content_category: @tott_cat
      expect(helper.ux2_content_path(tott)).to eq("/talk/#{tott.id}")
    end

    context 'when content is in subscategory' do
      let(:subcategory) { FactoryGirl.create :content_category, parent: @market_cat }
      let!(:content) { FactoryGirl.create :content, :located, content_category: subcategory }

      it 'should with path matching parent category name' do
        expect(helper.ux2_content_path(content)).to eq("/market/#{content.id}")
      end
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
      before { allow(ConsumerApp).to receive(:current).and_return consumer_app }

      it 'is generates url based on consumer_app uri' do
        expect(subject).to eql "#{consumer_app.uri}#{content_path}#{utm_string}"
      end
    end

    context 'if not consumer_app;' do
      before do
        @base_uri = nil
        allow(ConsumerApp).to receive(:current).and_return nil
      end

      it 'Uses a relative url' do
        expect(subject).to eql "#{content_path}#{utm_string}"
      end

      context 'when a consumer app exists matching the ENV DEFAULT_CONSUMER_HOST' do
        let(:default_host) {
          "Test.COM:9030"
        }
        let!(:consumer_app) { ConsumerApp.create uri: "http://#{default_host}" }

        before do
          allow(Figaro.env).to receive(:default_consumer_host).and_return(default_host)
        end

        it 'it uses default consumer app uri as the base' do
          expect(subject).to eql "#{consumer_app.uri}#{ux2_content_path(content)}#{utm_string}"
        end
      end
    end
  end

  describe "#organization_url_label" do
    it {expect(helper.organization_url_label(nil      )).to eq "" }
    it {expect(helper.organization_url_label(''       )).to eq "" }
    it {expect(helper.organization_url_label('foobar' )).to eq "foobar" }
    it {expect(helper.organization_url_label('foo/bar')).to eq "foo/bar" }

    ['', 'http://', 'https://'].each do |prefix|
      it {expect(helper.organization_url_label("#{prefix}dailyUV/my-org"                          )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV/123-my-org"                      )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV/organizations/my-org"            )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV/organizations/123-my-org"        )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV.com/my-org"                      )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV.com/123-my-org"                  )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV.com/organizations/my-org"        )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}dailyUV.com/organizations/123-my-org"    )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}www.dailyUV.com/my-org"                  )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}www.dailyUV.com/123-my-org"              )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}www.dailyUV.com/organizations/my-org"    )).to eq "dailyUV/my-org" }
      it {expect(helper.organization_url_label("#{prefix}www.dailyUV.com/organizations/123-my-org")).to eq "dailyUV/my-org" }
    end
  end
end
