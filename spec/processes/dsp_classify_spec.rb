require 'rails_helper'

RSpec.describe DspClassify do
  let(:content) { FactoryGirl.create :content }
  let(:repo) { FactoryGirl.create :repository }
  let(:cat_name) { 'news' }

  before { allow(DspService).to receive(:extract).with(content, repo) { extract_response_for_categories(cat_name) } }

  describe 'self.get_category_from_annotations' do
    context 'given annotations containing CATEGORIES' do
      subject { DspClassify.get_category_from_annotations(extract_response_for_categories(cat_name)) }

      it 'should return the category specified' do
        expect(subject.name).to eql cat_name
      end
    end

    context 'given annotations containing CATEGORY' do
      subject { DspClassify.get_category_from_annotations(extract_response_for_categories(cat_name, 'CATEGORY')) }

      it 'should return the category specified' do
        expect(subject.name).to eql cat_name
      end
    end

    context 'if categories are not in the annotations' do
      subject { DspClassify.get_category_from_annotations({ 'document-parts' => { 'feature-set' => [] } }) }

      it 'should return nil' do
        expect(subject).to be nil
      end
    end
  end
end

def extract_response_for_categories(cat_name, category_key='CATEGORIES')
  { 'document-parts' => {
    'feature-set' => [
      {"name"=>{"type"=>"XS_STRING", "name"=>category_key}, "value"=>{"type"=>"XS_STRING", "lang"=>nil, "value"=>cat_name}}
    ]}
  }
end
