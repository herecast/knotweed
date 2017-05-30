require 'rails_helper'

RSpec.describe DspService do
  before { allow_any_instance_of(Promotion).to receive(:update_active_promotions).and_return(true) }
  let(:content) { FactoryGirl.create :content }

  subject { DspService }

  it { is_expected.to respond_to(:post) }
  it { is_expected.to respond_to(:extract) }
  it { is_expected.to respond_to(:publish) }

  describe '#create_recommendation_doc_from_annotations' do
    let (:annotations) { {'id' => '1', 'annotation-sets' => []}  } 

    before do
      @content = content
      @content.update_attribute :pubdate, Date.today
    end

    subject { DspService.create_recommendation_doc_from_annotations(@content, annotations) }

    it 'should return a hash' do
      expect(subject.class).to be Hash
    end

    it 'should return the id from the annotations' do
      expect(subject[:id]).to eql '1'
    end

    it 'should include published' do
      expect(subject[:published]).to be_present
    end
  end

  describe '#record_user_visit' do
    let(:ontotext_key) { 'dsak32kds' }
    let(:repo) { FactoryGirl.build_stubbed :repository }
    let(:content) { FactoryGirl.build_stubbed :content, :news, id: 1 }
    let(:user_id) { '889' }

    before do
      allow(Figaro.env).to receive(:ontotext_recommend_key).and_return(ontotext_key)
    end

    subject { DspService.record_user_visit(content, user_id, repo) }

    it "posts to the user recommendation endpoint" do
      dsp_request = stub_request(:post, repo.recommendation_endpoint + '/user').with(
        body: {
          key: ontotext_key,
          userid: user_id,
          contentid: Content::BASE_URI + "/" + content.id.to_s
        }
      )

      subject
      expect(dsp_request).to have_been_requested
    end
  end
end
