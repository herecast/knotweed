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
    end
  end
end