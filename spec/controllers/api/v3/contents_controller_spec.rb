# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ContentsController, type: :controller do
  before do
    @org = FactoryGirl.create :organization
    FactoryGirl.create :organization, standard_ugc_org: true
  end

  describe 'GET #show', elasticsearch: true do
    context 'when content is removed' do
      before do
        @content = FactoryGirl.create :content, :news,
                                      removed: true,
                                      organization: @org
        allow(CreateAlternateContent).to receive(:call).and_return(@content)
      end

      subject { get :show, id: @content.id }
      subject { get :show, params: { id: @content.id } }

      it 'makes call to create alternate content' do
        expect(CreateAlternateContent).to receive(:call).with(
          @content
        )
        subject
      end
    end

    context 'when content is draft' do
      before do
        @content = FactoryGirl.create :content, :news,
                                      pubdate: nil,
                                      organization: @org
      end

      subject { get :show, params: { id: @content.id } }

      it 'returns not_found status' do
        subject
        expect(response).to have_http_status :not_found
      end

      context 'user can manage record' do
        before do
          @user = FactoryGirl.create :user
          api_authenticate user: @user

          @content.update created_by: @user
        end

        it 'returns the record' do
          subject
          expect(response).to have_http_status :ok
          expect(assigns(:content).id).to eql @content.id
        end

        context 'when draft is deleted' do
          before do
            @content.update_attribute :deleted_at, Time.current
          end

          it 'returns not_found status' do
            subject
            expect(response).to have_http_status :not_found
          end
        end
      end
    end

    context 'when content is scheduled to be published' do
      before do
        @content = FactoryGirl.create :content, :news,
                                      pubdate: Date.tomorrow,
                                      organization: @org
      end

      subject { get :show, params: { id: @content.id } }

      it 'returns not_found status' do
        subject
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      @user = FactoryGirl.create :user
      @content = FactoryGirl.create :content,
                                    pubdate: Time.current,
                                    created_by: @user
    end

    subject { delete :destroy, params: { id: @content.id } }

    context 'when no user logged in' do
      it 'it returns unauthorized status' do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when correct user logged in' do
      before do
        api_authenticate user: @user
      end

      context 'when contents is not a draft' do
        it 'returns ok status' do
          subject
          expect(response).to have_http_status :ok
        end
      end

      context 'when content is a draft' do
        before do
          @content.update_attribute(:pubdate, nil)
        end

        it 'marks Content as deleted' do
          expect { subject }.to change {
            @content.reload.deleted_at
          }
        end
      end
    end
  end

  describe 'creating content' do
    include ActiveJob::TestHelper

    context 'Signed in' do
      let(:user) do
        FactoryGirl.create :user
      end

      before do
        api_authenticate user: user
      end

      let(:location) do
        FactoryGirl.create :location
      end

      let(:content_params) do
        {
          title: 'Test title',
          content_type: 'market',
          content: 'Test Content',
          promote_radius: 10,
          location_id: location.id
        }
      end

      subject do
        post :create, params: { content: content_params }
      end

      context 'when successful' do
        before do
          env = double(production_messaging_enabled: 'true')
          allow(Figaro).to receive(:env).and_return env
        end

        it 'creates a new record' do
          expect { subject }.to change {
            Content.count
          }.by(1)
        end

        it 'triggers a facebook recache of that content' do
          expectations = lambda do |job|
            job[:args][0] == 'FacebookService' &&
              job[:args][1] == 'rescrape_url'
          end

          subject

          matching_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
            expectations[job]
          end
          expect(matching_jobs.length).to eq 1
        end

        context 'when pubdate is in the future' do
          before do
            content_params[:content_type] = 'news'
            content_params[:published_at] = 3.weeks.from_now
          end

          it 'does not trigger facebook recache' do
            expect(BackgroundJob).to_not receive(:perform_later).with(
              'FacebookService',
              'rescrape_url',
              kind_of(Content)
            )

            subject
          end
        end

        context 'when is draft (no pubdate)' do
          before do
            content_params[:content_type] = 'news'
            content_params[:published_at] = nil
          end

          it 'does not trigger facebook recache' do
            expect(BackgroundJob).to_not receive(:perform_later).with(
              'FacebookService',
              'rescrape_url',
              kind_of(Content)
            )

            subject
          end
        end

        describe 'Events' do
          let(:business_location) { FactoryGirl.create(:business_location) }
          let(:content_params) do
            {
              content_type: 'event',
              title: 'Concert',
              content: '<p>Tickets for sale a the doors</p>',
              cost: '$10',
              promote_radius: 10,
              venue_id: business_location.id,
              contact_email: 'test@test.com',
              location_id: FactoryGirl.create(:location).id,
              schedules: [
                {
                  days_of_week: [],
                  end_at: nil,
                  overrides: [],
                  presenter_name: nil,
                  repeats: 'once',
                  starts_at: 1.day.from_now.iso8601,
                  subtitle: nil,
                  weeks_of_month: []
                }
              ]
            }
          end

          context 'when user wants to advertise' do
            before do
              content_params[:wants_to_advertise] = true
            end

            it 'sends the adverising request' do
              mail = double
              expect(mail).to receive(:deliver_later)
              expect(AdMailer).to receive(:event_advertising_request).and_return(mail)

              subject
            end
          end

          context 'when user does not flag wants_to_advertise' do
            it 'does not send an email to admin' do
              expect(AdMailer).not_to receive(:event_advertising_request)
              subject
            end
          end

          context 'venue attributes given, not venue_id' do
            before do
              content_params.deep_merge!(
                venue: {
                  name: 'Norwich Historical Society',
                  address: '34 Elm Street',
                  city: 'Norwich',
                  state: 'VT'
                },
                venue_id: nil
              )
            end

            it 'creates a venue with venue attributes' do
              expect { subject }.to change {
                BusinessLocation.count
              }.by(1)

              expect(assigns(:content).channel.venue.name).to eq(content_params[:venue][:name])
            end
          end
        end
      end
    end
  end

  describe 'updating content' do
    context 'Signed in' do
      let(:user) do
        FactoryGirl.create :user
      end

      before do
        api_authenticate user: user
      end

      let(:content) do
        FactoryGirl.create :content, :market_post, created_by: user
      end

      let(:location) do
        FactoryGirl.create :location
      end

      let(:content_params) do
        {
          id: content.id,
          title: 'Test title',
          content: 'Test Content',
          promote_radius: 10,
          location_id: location.id
        }
      end

      subject do
        put :update, params: { id: content.id, content: content_params }
      end

      context 'when successful' do
        before do
          env = double(production_messaging_enabled: 'true')
          allow(Figaro).to receive(:env).and_return env
        end

        it 'triggers a facebook recache of that content' do
          expect(BackgroundJob).to receive(:perform_later).with(
            'FacebookService',
            'rescrape_url',
            content
          )

          subject
        end
      end

      describe 'updating event as admin' do
        let(:admin) { FactoryGirl.create :admin }

        before do
          api_authenticate user: admin
        end

        it 'should update fields' do
          subject
          expect(assigns(:content).title).to eql content_params[:title]
          expect(assigns(:content).content).to eql content_params[:content]
        end

        it 'should assign updated_by' do
          subject
          expect(assigns(:content).created_by).to eql user
          expect(assigns(:content).updated_by).to eql admin
        end
      end
    end
  end
end
