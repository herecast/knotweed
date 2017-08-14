require 'rails_helper'

RSpec.describe UgcSanitizer do

  def strip_whitespace(html)
    html.strip.gsub("\n","").gsub(/>\s+</,"><")
  end

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

    describe 'removing of empty html causing extra vertical space' do
      let(:input) do
        <<-HTML
        <p><img src="//placehold.it/30"></p>
        <p>hello World!</p>
        <br>
        <br>
        <br>
        <p>This Post has some extra padding in it</p>
        <p> </p>
        <p>
        </p>
        <p>
        <br>
        </p>
        <p><span><br></span></p>
        <p><br></p>
        <p><p><br></p></p>
        HTML
      end

      let(:expected_output) do
        <<-HTML
        <p><img src="//placehold.it/30"></p>
        <p>hello World!</p>
        <br>
        <br>
        <p>This Post has some extra padding in it</p>
        HTML
      end

      subject { described_class.call(input) }

      it do
        expect(strip_whitespace(subject)).to eql strip_whitespace(expected_output)
      end
    end
  end
end
