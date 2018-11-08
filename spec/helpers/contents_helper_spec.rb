require 'spec_helper' 

describe ContentsHelper, type: :helper do

  describe 'event_feed_content_path' do
    let(:event) { FactoryGirl.create :event }
    let(:utm_string) {"?utm_medium=email&utm_source=rev-pub&utm_content=#{ux2_content_path(event.content)}" }
    
    it 'should return /feed/#{content_id}?eventInstanceid=#{event_instance_id}' do
      expect(helper.event_feed_content_path(event.content)).to eq "#{ux2_content_path(event.content)}?eventInstanceId=#{event.next_instance.id}#{utm_string}"
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
    let(:utm_string) { "?utm_medium=email&utm_source=rev-pub&utm_content=#{content_path}" }
    before { allow(Figaro.env).to receive(:default_consumer_host).and_return("test.com") }

    it 'is generates url based on default_consumer_host env config' do
      expect(subject).to eql "http://#{Figaro.env.default_consumer_host}#{content_path}#{utm_string}"
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
