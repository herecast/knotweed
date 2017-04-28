# == Schema Information
#
# Table name: received_emails
#
#  id           :integer          not null, primary key
#  file_uri     :string
#  purpose      :string
#  processed_at :datetime
#  from         :string
#  to           :string
#  message_id   :string
#  record_id    :integer
#  record_type  :string
#  result       :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

RSpec.describe ReceivedEmail, type: :model do
  it { is_expected.to validate_presence_of(:file_uri) }
  it { is_expected.to validate_uniqueness_of(:file_uri).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:message_id).case_insensitive }

  it { is_expected.to belong_to(:record) }

  describe '#preprocess' do
    let(:file_uri) { "s3://bucket.tld/thefile" }
    subject { ReceivedEmail.new(file_uri: file_uri) }
    before do
      allow(subject).to receive(:message_object).and_return(Mail.new("To: subscribe@testsmtp.subtext.org\r\nFrom: Johnny Cash <user@example.org>\r\nMessage-ID: <CAEhfJmsv++nWFRw0vA7P3Er_1u7EYp4ccnyM6Cicz2y50T536Q@mail.gmail.com>\r\n\r\nBody Text"))
      subject.preprocess
    end

    it "sets #to field" do
      expect(subject.to).to eql "subscribe@testsmtp.subtext.org"
    end

    it "sets #from field" do
      expect(subject.from).to eql "user@example.org"
    end

    it "sets #message_id field" do
      expect(subject.message_id).to eql "CAEhfJmsv++nWFRw0vA7P3Er_1u7EYp4ccnyM6Cicz2y50T536Q@mail.gmail.com"
    end

    context 'with multiple to addresses' do
      before do
        allow(subject).to receive(:message_object).and_return(Mail.new("To: subscribe@testsmtp.subtext.org, user2@example.org\r\nFrom: Johnny Cash <user@example.org>\r\nMessage-ID: <CAEhfJmsv++nWFRw0vA7P3Er_1u7EYp4ccnyM6Cicz2y50T536Q@mail.gmail.com>\r\n\r\nBody Text"))
        subject.preprocess
      end

      it "sets #to field" do
        expect(subject.to).to eql "subscribe@testsmtp.subtext.org, user2@example.org"
      end
    end

    describe '#from' do
      context 'assigning' do
        it 'transforms to lowercase' do
          subject.from = "My@email.COM"
          expect(subject.from).to eql "my@email.com"
        end
      end
    end

    describe '#to' do
      context 'assigning' do
        it 'transforms to lowercase' do
          subject.to = "My@email.COM"
          expect(subject.to).to eql "my@email.com"
        end
      end
    end

    describe '#body' do
      context 'When email plain text and is not multi-part;' do
        let(:raw_email) {
          <<-EOS.strip_heredoc
          Delivered-To: raasdnil@gmail.com
          Received: by 10.140.178.13 with SMTP id a13cs354079rvf;
                  Fri, 21 Nov 2008 20:05:05 -0800 (PST)
          Received: by 10.151.44.15 with SMTP id w15mr2254748ybj.98.1227326704711;
                  Fri, 21 Nov 2008 20:05:04 -0800 (PST)
          }eturn-Path: <test@lindsaar.net>
          Received: from mail11.tpgi.com.au (mail11.tpgi.com.au [203.12.160.161])
                  by mx.google.com with ESMTP id 10si5117885gxk.81.2008.11.21.20.05.03;
                  Fri, 21 Nov 2008 20:05:04 -0800 (PST)
          Received-SPF: neutral (google.com: 203.12.160.161 is neither permitted nor denied by domain of test@lindsaar.net) client-ip=203.12.160.161;
          Authentication-Results: mx.google.com; spf=neutral (google.com: 203.12.160.161 is neither permitted nor denied by domain of test@lindsaar.net) smtp.mail=test@lindsaar.net
          X-TPG-Junk-Status: Message not scanned
          X-TPG-Antivirus: Passed
          Received: from [192.0.0.253] (60-241-138-146.static.tpgi.com.au [60.0.0.146])
            by mail11.tpgi.com.au (envelope-from test@lindsaar.net) (8.14.3/8.14.3) with ESMTP id mAM44xew022221
            for <raasdnil@gmail.com>; Sat, 22 Nov 2008 15:05:01 +1100
          Message-Id: <6B7EC235-5B17-4CA8-B2B8-39290DEB43A3@test.lindsaar.net>
          From: Mikel Lindsaar <test@lindsaar.net>
          To: Mikel Lindsaar <raasdnil@gmail.com>
          Content-Type: text/plain; charset=US-ASCII; format=flowed
          Content-Transfer-Encoding: 7bit
          Mime-Version: 1.0 (Apple Message framework v929.2)
          Subject: Testing 123
          Date: Sat, 22 Nov 2008 15:04:59 +1100
          X-Mailer: Apple Mail (2.929.2)

          I want to post this for sale.
          EOS
        }

        before do
          allow(subject).to receive(:message_object).and_return(Mail.new(raw_email))
        end

        it 'returns plain text content;' do
          expect(subject.body.strip).to eql "I want to post this for sale."
        end
      end

      context 'When email is muti-part text, but no html' do
        let(:raw_email) {
          <<-EOS.strip_heredoc
          Mime-Version: 1.0 (Apple Message framework v730)
          Content-Type: multipart/mixed; boundary=Apple-Mail-13-196941151
          Message-Id: <9169D984-4E0B-45EF-82D4-8F5E53AD7012@example.com>
          From: foo@example.com
          Subject: testing
          Date: Mon, 6 Jun 2005 22:21:22 +0200
          To: blah@example.com


          --Apple-Mail-13-196941151
          Content-Type: multipart/mixed;
            boundary=Apple-Mail-12-196940926


          --Apple-Mail-12-196940926
          Content-Transfer-Encoding: quoted-printable
          Content-Type: text/plain;
            charset=ISO-8859-1;
            delsp=yes;
            format=flowed

          This is the first part.

          --Apple-Mail-12-196940926
          Content-Transfer-Encoding: 7bit
          Content-Type: text/x-ruby-script;
            x-unix-mode=0666;
            name="test.rb"
          Content-Disposition: attachment;
            filename=test.rb

          puts "testing, testing"

          --Apple-Mail-12-196940926
          Content-Transfer-Encoding: base64
          Content-Type: application/pdf;
            x-unix-mode=0666;
            name="test.pdf"
          Content-Disposition: inline;
            filename=test.pdf

          YmxhaCBibGFoIGJsYWg=

          --Apple-Mail-12-196940926
          Content-Transfer-Encoding: 7bit
          Content-Type: text/plain;
            charset=US-ASCII;
            format=flowed



          --Apple-Mail-12-196940926--

          --Apple-Mail-13-196941151
          Content-Transfer-Encoding: base64
          Content-Type: application/pkcs7-signature;
            name=smime.p7s
          Content-Disposition: attachment;
            filename=smime.p7s

          jamisSqGSIb3DQEHAqCAMIjamisxCzAJBgUrDgMCGgUAMIAGCSqGSjamisEHAQAAoIIFSjCCBUYw
          ggQujamisQICBD++ukQwDQYJKojamisNAQEFBQAwMTELMAkGA1UEBhMCRjamisAKBgNVBAoTA1RE
          QzEUMBIGjamisxMLVERDIE9DRVMgQ0jamisNMDQwMjI5MTE1OTAxWhcNMDYwMjamisIyOTAxWjCB
          gDELMAkGA1UEjamisEsxKTAnBgNVBAoTIEjamisuIG9yZ2FuaXNhdG9yaXNrIHRpbjamisRuaW5=

          --Apple-Mail-13-196941151--
          EOS
        }

        before do
          allow(subject).to receive(:message_object).and_return(Mail.new(raw_email))
        end

        it 'returns text part' do
          expect(subject.body.strip).to eql "This is the first part."
        end
      end

      context 'When email is muti-part, html and text' do
        let(:text_content) {
          <<-EOS
This is *bold*
EOS
        }

        let(:html_content) {
          <<-EOS
<html>
  <head>

    <meta http-equiv="content-type" content="text/html; charset=utf-8">
  </head>
  <body text="#000000" bgcolor="#FFFFFF">
    This is <b>bold</b>
  </body>
</html>
EOS
        }

        let(:raw_email) {
          <<-EOS
Delivered-To: user@example.com
Received: by 10.36.212.71 with SMTP id x68csp178553itg;
        Fri, 27 May 2016 10:04:03 -0700 (PDT)
Return-Path: <user@example.com>
To: user@example.com
From: User <user@example.com>
Subject: test
Message-ID: <57487DFF.7000305@viciware.com>
Date: Fri, 27 May 2016 10:03:59 -0700
MIME-Version: 1.0
Content-Type: multipart/alternative;
 boundary="------------020003090000090104060303"

This is a multi-part message in MIME format.
--------------020003090000090104060303
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

#{text_content}

--------------020003090000090104060303
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 7bit

#{html_content}

--------------020003090000090104060303--

EOS
        }

        before do
          allow(subject).to receive(:message_object).and_return(Mail.new(raw_email))
        end

        it 'returns sanitized html part' do
          sanitized_html = Sanitize.fragment(html_content, subject.sanitize_config)
          expect(subject.body.strip).to eql sanitized_html.strip
        end
      end

      context 'When email is muti-part, html, enriched, and text' do
        let(:text_content) {
          <<-EOS
This is *bold*
EOS
        }

        let(:enriched_content) {
        <<-EOS
This is <bold>bold</bold>
EOS
        }

        let(:html_content) {
          <<-EOS
<html>
  <head>

    <meta http-equiv="content-type" content="text/html; charset=utf-8">
  </head>
  <body text="#000000" bgcolor="#FFFFFF">
    This is <b>bold</b>
  </body>
</html>
EOS
        }

        let(:raw_email) {
          <<-EOS
Delivered-To: user@example.com
Received: by 10.36.212.71 with SMTP id x68csp178553itg;
        Fri, 27 May 2016 10:04:03 -0700 (PDT)
Return-Path: <user@example.com>
To: user@example.com
From: User <user@example.com>
Subject: test
Message-ID: <57487DFF.7000305@viciware.com>
Date: Fri, 27 May 2016 10:03:59 -0700
MIME-Version: 1.0
Content-Type: multipart/alternative;
 boundary="------------020003090000090104060303"

This is a multi-part message in MIME format.
--------------020003090000090104060303
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

#{text_content}

--------------020003090000090104060303
Content-Type: text/enriched; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

#{enriched_content}

--------------020003090000090104060303
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 7bit

#{html_content}

--------------020003090000090104060303--

EOS
        }

        before do
          allow(subject).to receive(:message_object).and_return(Mail.new(raw_email))
        end

        it 'returns enriched text part' do
          expect(subject.body.strip).to eql enriched_content.strip
        end
      end
    end

    context 'When email TO is malformed and returned as a string, (real bug from prod)' do
      let(:email_with_unexpected_to) {
        File.read(Rails.root.join('spec','fixtures','emails','email_with_string_to.eml'))
      }

      subject { ReceivedEmail.new }
      before do
        allow(subject).to receive(:message_object).and_return(
          Mail.new(email_with_unexpected_to)
        )

        subject.preprocess
      end

      it '#to returns proper email' do
        expect(subject.to).to be_a String
        expect(subject.to).to include '@'
      end
    end
  end

  describe 'sender_name' do
    context 'when From includes name' do
      let(:from) { "Bob Dilley <bobo@dilley.net>" }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'returns name in the From field' do
        expect(email.sender_name).to eql "Bob Dilley"
      end
    end

    context 'when From has a name, but also a via' do
      let(:from) { "Bob Dilley <bobo@dilley.net> via GoBot <gobot.test@example.net>" }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'returns correct name' do
        expect(email.sender_name).to eql "Bob Dilley"
      end
    end

    context 'multiple from addresses, name included' do
      let(:from) { "Bob Dilley <bobo@dilley.net>, Alfred Doe <al@fred.rf>" }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'returns first sender name' do
        expect(email.sender_name).to eql "Bob Dilley"
      end
    end

    context 'email with punctuation and commas in name' do
      let(:from) {  "\"Tester, Albert D.\" <Albert.D.Tester@tuck.dartmouth.edu>"  }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'works' do
        expect(email.sender_name).to eql "Tester, Albert D."
      end

    end

    context 'no name included, just email' do
      let(:from) { "bobo@dilley.net" }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'returns part before @' do
        expect(email.sender_name).to eql "bobo"
      end
    end

    context 'no name included, just email. Multiple.' do
      let(:from) { "bobo@dilley.net, fred@flintstone.com" }
      let(:email) { ReceivedEmail.new }

      before do
        allow(email).to receive(:message_object).and_return(Mail.new("From: #{from}"))
      end

      it 'returns part before @' do
        expect(email.sender_name).to eql "bobo"
      end
    end
  end
end
