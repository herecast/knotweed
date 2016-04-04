require 'spec_helper'

describe DataContextsHelper, type: :helper do
  describe '#text_for_displaying_loaded_field' do
    context 'Given data with loaded = false' do
      let(:data_context) { double(loaded: false) }
      subject { helper.text_for_displaying_loaded_field(data_context) }

      it { should eql 'not loaded' }
    end

    context 'Given data with loaded = false' do
      let(:data_context) { double(loaded: true) }
      subject { helper.text_for_displaying_loaded_field(data_context) }

      it { should eql 'loaded' }
    end
  end
end
