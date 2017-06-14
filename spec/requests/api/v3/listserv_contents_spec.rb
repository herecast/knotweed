require 'rails_helper'

RSpec.describe "listserv contents endpoints", type: :request do
  describe 'GET /api/v3/listserv_contents/:key' do
    context 'when content exists;' do
      let(:listserv_content) { FactoryGirl.create :listserv_content }
      subject{ get '/api/v3/listserv_contents/' + listserv_content.key }

      it 'returns listserv content record json' do
        subject
        expect(response_json).to match({
          listserv_content: {
            id: listserv_content.key,
            listserv_id: listserv_content.listserv_id,
            subscription_id: listserv_content.subscription.key,
            user_id: listserv_content.user_id,
            subject: listserv_content.subject,
            body: listserv_content.body,
            sender_email: listserv_content.sender_email,
            sender_name: listserv_content.sender_name,
            verified_at: an_instance_of(String).or(be_nil),
            channel_type: an_instance_of(String).or(be_nil),
            content_id: a_kind_of(Fixnum).or(be_nil)
          }
        })
      end

      it 'returns status 200' do
        subject
        expect(response.status).to eql 200
      end
    end

    context 'when content does not exist' do
      it 'returns status 404' do
        get '/api/v3/listserv_contents/not-a-key'
        expect(response.status).to eql 404
      end
    end

    context 'when there is no user_id' do
      let(:user) { FactoryGirl.create :user }
      let(:new_user_listserv_content) { FactoryGirl.create :listserv_content, user_id: nil, sender_email: user.email }
      it 'returns the user_id the sender_email matches an existing user' do
        get "/api/v3/listserv_contents/#{new_user_listserv_content.key}"
        expect(response_json[:listserv_content][:user_id]).to eq user.id
      end
    end

    context 'when body is "No content found"' do
      let (:empty_body_content) { FactoryGirl.create :listserv_content, body: "No content found" }

      it 'returns an empty string as the content body' do
        get "/api/v3/listserv_contents/#{empty_body_content.key}"
        expect(response_json[:listserv_content][:body]).to eq ""
      end

      subject{ get '/api/v3/listserv_contents/' + listserv_content.key }
    end
  end

  describe 'PATCH /api/v3/listserv_contents/:key' do
    let!(:channel_category) { ContentCategory.find_or_create_by(name: 'market') }
    let(:listserv_content) { FactoryGirl.create :listserv_content }
    let(:model_params) {
      {
        subject: "my new subject line",
        body: "I changed the body too.",
        channel_type: 'market',
        sender_name: 'Huck Finn'
      }
    }

    subject { patch "/api/v3/listserv_contents/#{listserv_content.key}",
              listserv_content: model_params }

    context 'when already verified' do
      before do
        listserv_content.update! verified_at: Time.current, verify_ip: '192.168.1.1'
      end

      it 'returns 422 status' do
        subject
        expect(response.status).to eql 422
      end
    end

    context 'when not verified' do
      let(:remote_ip) { '192.168.0.1' }
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(remote_ip)
      end

      it 'updates record' do
        subject
        expect(response_json).to match(
          listserv_content: {
            id: listserv_content.key,
            listserv_id: listserv_content.listserv_id,
            subscription_id: listserv_content.subscription.key,
            user_id: listserv_content.user_id,
            subject: model_params[:subject],
            body: model_params[:body],
            sender_email: listserv_content.sender_email,
            sender_name: model_params[:sender_name],
            verified_at: an_instance_of(String),
            channel_type: model_params[:channel_type],
            content_id: a_kind_of(Fixnum).or(be_nil)
          }
        )
      end

      it 'returns 200 status' do
        subject
        expect( response ).to have_http_status(200)
      end

      it 'passes model and attributes to VerifyAndUpdateListservContent' do

        expect(VerifyAndUpdateListservContent).to receive(:call).with(
          listserv_content, a_hash_including({
            subject: model_params[:subject],
            body: model_params[:body]
          }))
        subject
      end

      it 'sets verify_ip to remote_ip' do
        expect{subject}.to change{
          listserv_content.reload.verify_ip
        }.to(remote_ip)
      end

      context 'when ContentOwnerMismatch is raised' do
        before do
          allow(VerifyAndUpdateListservContent).to receive(:call).and_raise(ContentOwnerMismatch)
        end

        it 'returns status 422' do
          subject
          expect(response.status).to eql 422
        end
      end

      context 'when ListservExceptions::AlreadyVerified is raised' do
        before do
          allow(VerifyAndUpdateListservContent).to receive(:call).and_raise(
            ListservExceptions::AlreadyVerified.new(listserv_content)
          )
        end

        it 'returns status 422' do
          subject
          expect(response.status).to eql 422
        end
      end

      context 'when ListservExceptions::BlacklistedSender is raised' do
        before do
          allow(VerifyAndUpdateListservContent).to receive(:call).and_raise(
            ListservExceptions::BlacklistedSender.new(
              listserv_content.listserv,
              listserv_content.sender_email)
          )
        end

        it 'returns status 422' do
          subject
          expect(response.status).to eql 422
        end
      end
    end
  end

  describe 'GET /api/v3/listserv_contents/:key/verify (HTML)' do
    let(:remote_ip) { '192.168.0.1' }
    before do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(remote_ip)
    end

    context 'when content exists;' do
      let(:listserv_content) { FactoryGirl.create :listserv_content }
      subject{ get '/api/v3/listserv_contents/' + listserv_content.key + '/verify', format: 'html' }

      it 'passes record to VerifyAndUpdateListservContent process' do
        expect(VerifyAndUpdateListservContent).to receive(:call).with(
          listserv_content,
          {verify_ip: remote_ip}
        )
        subject
      end

      context 'not verified yet' do
        before do
          listserv_content.update verified_at: nil
        end

        it "displays correct You're all set message" do
          subject
          expect(response.body).to include("You're all set")
          expect(response.body).to include("Your post will appear in tomorrow's #{listserv_content.listserv.name} digest, but not on dailyUV")
        end

        it 'sets verify_ip to remote_ip' do
          expect{subject}.to change{
            listserv_content.reload.verify_ip
          }.to(remote_ip)
        end

        it 'verifies the listserv content record' do
          expect{subject}.to change{
            listserv_content.reload.verified_at
          }.to(instance_of(ActiveSupport::TimeWithZone))
        end

        context 'when active feature flag: listserv-user-testing' do
          before do
            FactoryGirl.create :feature, active: true, name: 'listserv-user-testing'
          end

          it 'displays "TEST" in the title' do
            subject
            expect(response.body).to include("Daily UV TEST")
          end

          it 'says "not on dailyUV TEST website"' do
            subject
            expect(response.body).to include("not on dailyUV TEST website")
          end
        end

      end

      context 'already verified' do
        before do
          listserv_content.update verified_at: Time.zone.now, verify_ip: remote_ip
        end

        it "displays correct You're all set message" do
          subject
          expect(response.body).to include("You're all set")
          expect(response.body).to include("You have already verified this post. Thank you!")
        end

      end
    end
  end
end
