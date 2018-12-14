require 'rails_helper'

RSpec.describe UgcSanitizer do
  def strip_whitespace(html)
    html.strip.gsub("\n", "").gsub(/>\s+</, "><")
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

    context "Given HTML string with base64 encoded image" do
      let(:base64) { 'data:image/gif;base64,R0lGODlhQABAAMQAAPr8/WOi08Xc7nOs1+ry+bbT6tPl8uHt9n2y2rnV64O13Iq53ZrD4svg8O71+tno9PT5/Nzq9ZK+4KvN56XK5fD2+2il1L7Y7OXw+G2o1aDH5K7P6Mnf7/f6/f///16f0SH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS4zLWMwMTEgNjYuMTQ1NjYxLCAyMDEyLzAyLzA2LTE0OjU2OjI3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjU4MjA1Qjg4RDNGQkUwMTE4Nzk5REVGNjE5OUJCQUIyIiB4bXBNTTpEb2N1bWVudElEPSJ4bXAuZGlkOjRCNUNDQzA4MDU0OTExRTQ5QzVBQjIwOTAzQThGMDA0IiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjRCNUNDQzA3MDU0OTExRTQ5QzVBQjIwOTAzQThGMDA0IiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCBDUzYgKFdpbmRvd3MpIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6QzVFOUFCQUU4OEY0RTMxMTk1QkVCNjg0MzkyQjk4OTkiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6NTgyMDVCODhEM0ZCRTAxMTg3OTlERUY2MTk5QkJBQjIiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4B//79/Pv6+fj39vX08/Lx8O/u7ezr6uno5+bl5OPi4eDf3t3c29rZ2NfW1dTT0tHQz87NzMvKycjHxsXEw8LBwL++vby7urm4t7a1tLOysbCvrq2sq6qpqKempaSjoqGgn56dnJuamZiXlpWUk5KRkI+OjYyLiomIh4aFhIOCgYB/fn18e3p5eHd2dXRzcnFwb25tbGtqaWhnZmVkY2JhYF9eXVxbWllYV1ZVVFNSUVBPTk1MS0pJSEdGRURDQkFAPz49PDs6OTg3NjU0MzIxMC8uLSwrKikoJyYlJCMiISAfHh0cGxoZGBcWFRQTEhEQDw4NDAsKCQgHBgUEAwIBAAAh+QQAAAAAACwAAAAAQABAAAAF/+AnjmRpnmiqrmzrvnAsz3Rt33iu73zv/73BxODoGI/IpHJpdBg2g1zBQ61ar9islpqwBR7bsDh8sNAi47S6iplt1vD0JZaJ28XR1+TOzxZgaH2CVAQwB0yIiYpMhUCOj5ApBwSUlZaXmJmamwQHMIOgHjAdoX0do2mdB6sRBgYCYIKnL6RbGBIDASW6CwaDsy61WRsfChwHAnkWDxChwC3CVwwfElYAeQilzyzRVRwizVaeIhTOqFgZH3VYCiIBAKDbK90e4+tXcyIH8edWDSMVsEQYse9XvyoGRgjAUsEdvC0UECBY8DCLPBX0gGW70mhPGAQj6FW5mELkhBEcrv/8GVBRywIRFkRSIYlC5ksRKan8UyDTys2YW2ie6Dkh3YcBEkBuHCMBZhihJnp6AGDgwjQRLa044NCgawOQHwII8MoBgxWoJaQidOdAiwAX5UYe3JJQxACzWP61eCOXlpp2KLG8baHh7NyzHJIiyDMiAccCkCHnCRAZcqCZhz040GCXQQEDB67iDNP0g4Wnhw3oUkBA8Ih3W372REui27gFWx6M8OUS5uy5gAtq6fLhwhawH377rdLoQzgtDT802CLBgoUByoOJG3E5S/SeAIxkvUI7pDVdH3Bv6cJXFoyAVvJ9YCDyn/pBEGDEskJhhAUNDRyAQQQFgFRYKOO4MAVYFgZIgF4JCuwHinwtDLAFBK8kkMAFEpbCmAvGlRLHNzLgJWIaFTwIgwUmnrgFAR/KEKKLWQigIg0IFBBBBYv0mEQFESSAXCREFmnkkUgmqeSSTDbpJA4hAAA7' }
      let(:input) {
        <<-HTML
        <p>This is here</p>
        <img src="#{base64}" />
        HTML
      }

      subject { described_class.call(input) }

      it "removes the img src" do
        expect(subject.strip).to_not include(base64)
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
