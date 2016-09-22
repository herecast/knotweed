require 'rails_helper'

RSpec.describe UgcSanitizer do
  describe '.call' do
    context "Given HTML string with style tags" do
      let(:input) {
        <<-HTML
        <style>
          p { color: red; }
        </style>
        <p>This wont be red</p>
        HTML
      }

      subject { described_class.call(input) }

      it "removes style tags, and contents" do
        expect(subject.strip).to eql "<p>This wont be red</p>"
      end
    end
  end
end
