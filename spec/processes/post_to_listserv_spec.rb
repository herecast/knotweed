require 'rails_helper'

RSpec.describe PostToListserv do
  let(:category) { FactoryGirl.create :content_category }
  before do
    allow(DspClassify).to receive(:call).and_return(category)
  end

  context 'Given a ReceivedEmail' do
    let(:listserv) { FactoryGirl.create :subtext_listserv }
    let!(:email) { FactoryGirl.create :received_email, from: 'test@test.com' }

    before do
      allow(email).to receive(:sender_name).and_return('test person')
    end

    subject { PostToListserv.call(listserv, email) }

    it "returns a persisted matching ListervContent record" do
      expect(subject).to be_an_instance_of(ListservContent)
      expect(subject).to be_persisted

      expect(subject.subject).to eql email.subject
      expect(subject.sender_email).to eql email.from
      expect(subject.sender_name).to eql email.sender_name
      expect(subject.listserv).to eql listserv
    end

    it "categorizes record" do
      subject
      expect(subject.content_category).to eql category
    end

    describe 'if categorization fails' do
      before do
        # this is kind of funky. We don't really care what the args to DspExceptions::UnableToClassify
        # are for this test, but rspec won't let me call
        #   and_raise(DspExceptions::UnableToClassify, arg1, arg2)
        # it doesn't seem to pass the args on properly, it only takes a single "message."
        # So I have to make do with passing it a specific instance that we generate here.
        exception = DspExceptions::UnableToClassify.new(email, FactoryGirl.create(:repository))
        allow(DspClassify).to receive(:call).with(any_args).and_raise(exception)
      end

      it 'should rescue and assign default category of market' do
        subject
        expect(subject.content_category).to eql ContentCategory.find_or_create_by(name: 'market')
      end
    end

    it "sends verification email" do
      expect(NotificationService).to receive(:posting_verification).with(instance_of(ListservContent))
      subject
    end

    it "sets #verification_email_sent_at" do
      expect(subject.verification_email_sent_at).to be_a ActiveSupport::TimeWithZone
    end

    context 'when subscription exists' do
      let!(:subscription) { FactoryGirl.create :subscription,
                           email: email.from, listserv: listserv }
      it 'has subscription assigned' do
        expect(subject.subscription).to eql subscription
      end

      context 'when subscription has user record' do
        let!(:user) { FactoryGirl.create :user }
        before do
          subscription.update user: user
        end

        it 'has user assigned' do
          expect(subject.user).to eql user
        end
      end
  
      context 'when content.body text is empty' do
        let(:empty_text_email) { FactoryGirl.create :received_email, file_uri: "#{Rails.root}/spec/fixtures/emails/empty_body_text_email.eml"}

        subject { PostToListserv.call(listserv, empty_text_email) }

        it 'adds content to the body before sending to DSP' do
          expect(subject.body).to eql 'No content found'
        end

        context 'when content.body html is empty' do
          let(:empty_html_email) { FactoryGirl.create :received_email, file_uri: "#{Rails.root}/spec/fixtures/emails/empty_body_html_email.eml"} 
          subject { PostToListserv.call(listserv, empty_html_email) }

          it 'adds content to the body before sending to DSP' do
            expect(subject.body).to eql 'No content found'
          end
        end
      end
    end

    context 'when subject text is empty' do
      let(:empty_subject_email) { FactoryGirl.create :received_email, file_uri: "#{Rails.root}/spec/fixtures/emails/empty_subject.eml"}
      subject { PostToListserv.call(listserv, empty_subject_email) }

      it 'adds ? to subject' do
        expect(subject.subject).to eql '?'
      end
    end


    context 'when user exists with matching email' do
      let!(:user) { FactoryGirl.create :user, email: email.from }

      it "assigns user" do
        expect(subject.user).to eql user
      end
    end

    context 'when sender is blacklisted' do
      before do
        FactoryGirl.create :subscription, {
          listserv: listserv,
          email: email.from,
          blacklist: true
        }
      end

      it "raises exception" do
        expect{ subject }.to raise_error(ListservExceptions::BlacklistedSender)
      end
    end

    describe 'ListservContent#body' do
      it 'is equal to sanitized ReceivedEmail#body' do
        expect(subject.body).to eql UgcSanitizer.call(email.body)
      end
    end
  end
end
