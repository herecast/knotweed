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
end
