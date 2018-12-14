# frozen_string_literal: true

require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe '#display_base_errors' do
    context 'Given a resource with base errors empty' do
      let(:resource) { double(errors: { base: [] }) }
      subject { helper.display_base_errors(resource) }

      it { is_expected.to be_blank }
    end

    context 'Given a resource with multiple base errors' do
      let(:errors) { ['error 1', 'Error 2'] }
      let(:resource) do
        double(errors: {
                 base: errors
               })
      end
      subject { helper.display_base_errors(resource) }
      it 'generates html with all the error messages' do
        expect(subject).to satisfy { |html| errors.all? { |e| html.include?(e) } }
      end
    end
  end

  describe '#is_config_controller_class' do
    subject { helper.is_config_controller_class }

    context 'for a config controller' do
      before { allow(controller).to receive(:controller_name).and_return(ApplicationHelper::CONFIG_CONTROLLERS[0]) }
      it { expect(subject).to eq 'in' }
    end

    context 'for a non-config controller' do
      before { allow(controller).to receive(:controller_name).and_return('fake_non_config') }
      it { expect(subject).to eq '' }
    end
  end
end
