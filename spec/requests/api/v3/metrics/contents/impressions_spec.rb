require 'rails_helper'

RSpec.describe 'Content Impressions' do
  describe 'POST /api/v3/metrics/contents/:id/impressions', inline_jobs: true do
    let(:remote_ip) { '1.1.1.1' }
    let(:user_agent) { "AmigaVoyager/3.4.4 (MorphOS/PPC native)" }

    let(:context_data) {
      { client_id: '1222kk898943' }
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

    context 'given a content id for news' do
      let(:news) { FactoryGirl.create :content, :news }

      subject {
        post "/api/v3/metrics/contents/#{news.id}/impressions",
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
          content,
          'impression',
          date.to_s,
          a_hash_including({
            user_agent: user_agent,
            user_ip: remote_ip,
            client_id: context_data[:client_id]
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
            content,
            'impression',
            date.to_s,
            a_hash_including({
              user_agent: user_agent,
              user_ip: remote_ip,
              user_id: user.id,
              client_id: context_data[:client_id]
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
        let(:content) { news }
      end
    end

    context 'given a talk content id' do
      let(:talk) { FactoryGirl.create :content, :talk }

      subject {
        post "/api/v3/metrics/contents/#{talk.id}/impressions",
          context_data,
          headers
      }

      it 'returns 202 status' do
        subject
        expect(response.status).to eql 202
      end

      # This constraint should eventually be removed
      it 'does not record a content metric impression' do
        expect(RecordContentMetric).to_not receive(:call)

        subject
      end

      it 'does increment the content view count' do
        expect{subject}.to change{talk.reload.view_count}.by(1)
      end

      include_examples 'DSP visit recording' do
        let(:content) { talk }
      end
    end

    context 'given a market content id' do
      let(:market_content) { FactoryGirl.create(:market_post).content }

      subject {
        post "/api/v3/metrics/contents/#{market_content.id}/impressions",
          context_data,
          headers
      }

      it 'returns 202 status' do
        subject
        expect(response.status).to eql 202
      end

      # This constraint should eventually be removed
      it 'does not record a content metric impression' do
        expect(RecordContentMetric).to_not receive(:call)

        subject
      end

      it 'does increment the content view count' do
        expect{subject}.to change{market_content.reload.view_count}.by(1)
      end

      include_examples 'DSP visit recording' do
        let(:content) { market_content }
      end
    end

    context 'given an event content id' do
      let(:event_content) { FactoryGirl.create(:event).content }

      subject {
        post "/api/v3/metrics/contents/#{event_content.id}/impressions",
          context_data,
          headers
      }

      it 'returns 202 status' do
        subject
        expect(response.status).to eql 202
      end

      # This constraint should eventually be removed
      it 'does not record a content metric impression' do
        expect(RecordContentMetric).to_not receive(:call)

        subject
      end

      it 'does increment the content view count' do
        expect{subject}.to change{event_content.reload.view_count}.by(1)
      end

      include_examples 'DSP visit recording' do
        let(:content) { event_content }
      end
    end
  end
end
