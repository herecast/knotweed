require 'rails_helper'

RSpec.describe 'Content Impressions' do
  describe 'POST /api/v3/metrics/contents/:id/impressions', inline_jobs: true do
    let(:remote_ip) { '1.1.1.1' }
    let(:user_agent) { "AmigaVoyager/3.4.4 (MorphOS/PPC native)" }

    let(:location) { FactoryGirl.create :location, slug: 'newton-nh' }
    let(:context_data) {
      { client_id: '1222kk898943', location_id: location.slug }
    }

    let(:consumer_app) {
      FactoryGirl.create(:consumer_app,
          repository: FactoryGirl.create(:repository))
    }

    let(:headers) {
      {'Consumer-App-Uri' => consumer_app.uri}
    }

    subject {
      post "/api/v3/metrics/contents/#{content.id}/impressions",
        context_data,
        headers
    }

    shared_examples "DSP visit recording" do
      it 'records a visit to the DSP service with client_id' do
        expect(DspService).to receive(:record_user_visit).with(
          content,
          context_data[:client_id],
          a_kind_of(Repository)
        )

        subject
      end

      context 'no client id provided' do
        before do
          context_data[:client_id] = nil
        end

        it 'does not record a visit with the DSP service' do
          expect(DspService).to_not receive(:record_user_visit)
          subject
        end
      end

      context 'user is signed in' do
        let(:user) { FactoryGirl.create(:user) }

        before do
          headers.merge! auth_headers_for(user)
        end

        it 'records a visit to the DSP service with user email' do
          expect(DspService).to receive(:record_user_visit).with(
            content,
            user.email,
            a_kind_of(Repository)
          )

          subject
        end

        context 'analytics_blocked for user' do
          before do
            user.update skip_analytics: true
          end

          it 'does not record a visit to the dsp' do
            expect(DspService).to_not receive(:record_user_visit)
            subject
          end
        end
      end
    end

    before do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(remote_ip)
      allow_any_instance_of(ActionDispatch::Request).to receive(:user_agent).and_return(user_agent)

      stub_request(:post, consumer_app.repository.recommendation_endpoint + '/user')
    end

    [:news, :talk, :market_post, :event].each do |type|
      context "given a content id for #{type.to_s}" do
        let(:record) { FactoryGirl.create :content, type }

        subject {
          post "/api/v3/metrics/contents/#{record.id}/impressions",
            context_data,
            headers
        }

        it 'returns 202 status' do
          subject
          expect(response.status).to eql 202
        end

        it 'records a content metric impression' do
          date = Date.current

          expect(RecordContentMetric).to receive(:call).with(
            record,
            a_hash_including({
              event_type: 'impression',
              current_date: date.to_s,
              user_agent: user_agent,
              user_ip: remote_ip,
              client_id: context_data[:client_id],
              location_id: location.id
            })
          )

          subject
        end

        context 'user is signed in' do
          let(:user) { FactoryGirl.create(:user) }

          before do
            headers.merge! auth_headers_for(user)
          end

          it 'records a content metric impression' do
            date = Date.current

            expect(RecordContentMetric).to receive(:call).with(
              record,
              a_hash_including({
                event_type: 'impression',
                current_date: date.to_s,
                user_agent: user_agent,
                user_ip: remote_ip,
                user_id: user.id,
                client_id: context_data[:client_id],
                location_id: location.id
              })
            )

            subject
          end

          context 'analytics_blocked for user' do
            before do
              user.update skip_analytics: true
            end

            it 'does not record a content metric impression' do
              expect(RecordContentMetric).to_not receive(:call)

              subject
            end
          end
        end


        include_examples 'DSP visit recording' do
          let(:content) { record }
        end
      end

    end
  end
end
