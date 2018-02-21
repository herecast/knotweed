require 'spec_helper'

describe Api::V3::ContentsController, :type => :controller do
  before do
    @repo = FactoryGirl.create :repository
    @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
    @org = FactoryGirl.create :organization
    @consumer_app.organizations = [@org]
  end

  describe 'GET #show' do
    context "when content is removed" do
      before do
        @content = FactoryGirl.create :content, :news,
          removed: true,
          organization: @org
        allow(CreateAlternateContent).to receive(:call).and_return(@content)
      end

      subject { get :show, { id: @content.id, consumer_app_uri: @consumer_app.uri } }

      it "makes call to create alternate content" do
        expect(CreateAlternateContent).to receive(:call).with(
          @content
        )
        subject
      end
    end

    context "when content is draft" do
      before do
        @content = FactoryGirl.create :content, :news,
          pubdate: nil,
          organization: @org
      end

      subject { get :show, { id: @content.id, consumer_app_uri: @consumer_app.uri } }

      it "returns not_found status" do
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
      end
    end

    context "when content is scheduled to be published" do
      before do
        @content = FactoryGirl.create :content, :news,
          pubdate: Date.tomorrow,
          organization: @org
      end

      subject { get :show, { id: @content.id, consumer_app_uri: @consumer_app.uri } }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe 'GET similar_content', elasticsearch: true do
    before do
      ENV['sim_stack_categories'] = nil
      @content = FactoryGirl.create(:content)
      @content_id = @content.id
      # note, similar content is filtered by organization so we need to ensure this has
      # a organization that exists in the consumer app's list.
      #@market_cat = FactoryGirl.create :content_category, name: 'market'
      @sim_content1 = FactoryGirl.create :content, organization: @org
      @sim_content1_es = Content.search('*', where: {id: @sim_content1.id}, load: false).first
      @sim_content2 = FactoryGirl.create :content, :market_post, organization: @org
      @sim_content2_es = Content.search('*', where: {id: @sim_content2.id}, load: false).first
      request_body = {'articles'=>[{'id'=>"#{Content::BASE_URI}/#{@sim_content1.id}"},
        {'id'=>"#{Content::BASE_URI}/#{@sim_content2.id}"}]}.to_json
      stub_request(:get, /recommend\/contextual\?contentid=/).
        to_return(:status => 200,
          :body => request_body,
          :headers => { 'Content-Type' => 'application/json;charset=UTF-8' })
    end

    subject { get :similar_content, format: :json,
        id: @content_id, consumer_app_uri: @consumer_app.uri }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    context 'with sim_stack_categories environment variable set' do
      before do
        ENV['sim_stack_categories'] = 'market'
      end

      it 'should only return similar content in that category' do
        subject
        expect(assigns(:contents).map(&:id)).to eq([@sim_content2.id])
      end
    end

    it 'responds with relation of similar content' do
      subject
      expect(assigns(:contents)).to match_array([@sim_content1_es, @sim_content2_es])
    end

    describe 'drafts' do
      before do
        @sim_content1.update_attribute :pubdate, nil
      end

      it 'should not be returned' do
        subject
        expect(assigns(:contents)).not_to include(@sim_content1)
      end
    end

    describe 'scheduled content' do
      before do
        @sim_content1.update_attribute :pubdate, 2.weeks.from_now
      end

      it 'should not be returned' do
        subject
        expect(assigns(:contents)).not_to include(@sim_content1)
      end
    end

    context 'when similar content contains events with instances in the past or future' do
      before do
        event_category = FactoryGirl.create :content_category, :event
        @root_content = FactoryGirl.create :content,
          :located,
          organization: @org
        @future_content = FactoryGirl.create :content,
          :located,
          content_category: event_category,
          organization: @org
        @past_content = FactoryGirl.create :content,
          :located,
          content_category: event_category,
          organization: @org
        event = FactoryGirl.create :event, skip_event_instance: true, content: @future_content
        other_event = FactoryGirl.create :event, skip_event_instance: true, content: @past_content
        FactoryGirl.create :event_instance, event: other_event, start_date: 1.week.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.week.from_now
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.from_now
        @future_content.reload.reindex
        @past_content.reload.reindex

        @sim_content = Content.search('*', where: {id: [@future_content.id, @past_content.id]}, load: false).to_a

        allow_any_instance_of(Content).to receive(:similar_content).with(@repo, 20, any_args).and_return(@sim_content)
      end

      subject { get :similar_content, format: :json, id: @root_content.id, consumer_app_uri: @consumer_app.uri }

      it 'should response with events that have instances in the future' do
        subject
        returned_ids = assigns(:contents).map(&:id)
        expect(returned_ids).to eql [@future_content.id]
      end
    end

    context 'for sponsored_content' do
      before do
        @content.content_category_id = FactoryGirl.create(:content_category, name: 'sponsored_content').id
        @some_similar_contents = FactoryGirl.create_list(:content, 3, organization: @org)
        @some_similar_contents_es = Content.search('*',
                                                   where: {id: @some_similar_contents.map(&:id)},
                                                   order: {pubdate: :desc},
                                                   load: false)
        @content.similar_content_overrides = @some_similar_contents.map{|c| c.id}
        @content.save
      end

      it 'should respond with the contents defined by similar_content_overrides' do
        subject
        expect(assigns(:contents)).to match_array(@some_similar_contents_es)
      end
    end
  end

  describe 'POST /contents/:id/moderate' do
    subject { post :moderate, id: @content.id, flag_type: 'Inappropriate' }

    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user

      api_authenticate user: @user
    end

    it 'should queue flag notification email' do
      expect {
        subject
      }.to change{ActiveJob::Base.queue_adapter.enqueued_jobs.size}.by(1)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:job]).to eq(ActionMailer::DeliveryJob)
    end

  end

  describe 'GET /contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    subject { get :metrics, id: @content.id }

    context 'without owning the content' do
      before do
        @content.update_attribute :created_by, nil
      end
      it 'should respond with 403' do
        subject
        expect(response.code).to eq('403')
      end
    end

    context 'as content owner' do
      before do
        @content.update_attribute :created_by, @user
      end

      it 'should respond with the content' do
        subject
        expect(assigns(:content)).to eq(@content)
      end
    end
  end

  describe 'creating content' do
    context 'Signed in' do
      let(:user) do
        FactoryGirl.create :user
      end

      before do
        api_authenticate user: user
      end

      let(:location) {
        FactoryGirl.create :location
      }

      let(:content_params) {
        {
          title: 'Test title',
          content_type: 'market',
          content: 'Test Content',
          promote_radius: 10,
          ugc_base_location_id: location.slug
        }
      }

      subject do
        post :create, {content: content_params, consumer_app_uri: @consumer_app.uri}
      end

      context 'when successful' do
        it 'creates a new record' do
          expect{ subject }.to change{
            Content.count
          }.by(1)
        end

        it 'runs content through UpdateContentLocations process' do
          expect(UpdateContentLocations).to receive(:call).with(kind_of(Content), promote_radius: content_params[:promote_radius], base_locations: [location])

          subject
        end

        it 'triggers a facebook recache of that content' do
          expect(BackgroundJob).to receive(:perform_later).with(
            'FacebookService',
            'rescrape_url',
            kind_of(Content)
          )

          subject
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

        it 'publishes the content' do
          expect(PublishContentJob).to receive(:perform_later).with(
            kind_of(Content),
            kind_of(Repository),
            Content::DEFAULT_PUBLISH_METHOD
          )

          subject
        end

        context 'listserv ids included' do
          let(:listservs) {
            FactoryGirl.create_list(:listserv, 2)
          }
          before do
            content_params.merge!(listserv_ids: listservs.map(&:id))
          end

          it 'promotes to listservs' do
            expect(PromoteContentToListservs).to receive(:call).with(
              kind_of(Content),
              @consumer_app,
              request.remote_ip,
              *listservs
            )

            subject
          end
        end

        describe 'Events' do
          let(:business_location) { FactoryGirl.create(:business_location) }
          let(:content_params) {
            {
              content_type: 'event',
              title: "Concert",
              content: "<p>Tickets for sale a the doors</p>",
              cost: "$10",
              promote_radius: 10,
              venue_id: business_location.id,
              contact_email: 'test@test.com',
              ugc_base_location_id: FactoryGirl.create(:location).slug,
              schedules: [
                {
                  days_of_week: [],
                  end_at: nil,
                  overrides: [],
                  presenter_name: nil,
                  repeats: "once",
                  starts_at: 1.day.from_now.iso8601,
                  subtitle: nil,
                  weeks_of_month: []
                }
              ]
            }
          }

          context "when user wants to advertise" do
            before do
              content_params[:wants_to_advertise] = true
            end

            it "sends the adverising request" do
              mail = double()
              expect(mail).to receive(:deliver_later)
              expect(AdMailer).to receive(:event_adveritising_request).and_return(mail)

              subject
            end
          end

          context "when user does not flag wants_to_advertise" do
            it "does not send an email to admin" do
              expect(AdMailer).not_to receive(:event_adveritising_request)
              subject
            end
          end

          context 'venue attributes given, not venue_id' do
            before do
              content_params.deep_merge!(
                venue: {
                  name: "Norwich Historical Society",
                  address: "34 Elm Street",
                  city: "Norwich",
                  state: "VT"
                },
                venue_id: nil
              )
            end

            it 'creates a venue with venue attributes' do
              expect{subject}.to change{
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


      let(:location) {
        FactoryGirl.create :location
      }

      let(:content_params) {
        {
          id: content.id,
          title: 'Test title',
          content: 'Test Content',
          promote_radius: 10,
          ugc_base_location_id: location.slug
        }
      }

      subject do
        put :update, {id: content.id, content: content_params, consumer_app_uri: @consumer_app.uri}
      end

      context 'when successful' do
        it 'triggers a facebook recache of that content' do
          expect(BackgroundJob).to receive(:perform_later).with(
            'FacebookService',
            'rescrape_url',
            content
          )

          subject
        end

        it 'runs content through UpdateContentLocations process' do
          expect(UpdateContentLocations).to receive(:call).with(content, promote_radius: content_params[:promote_radius], base_locations: [location])

          subject
        end

        it 'publishes the content' do
          expect(PublishContentJob).to receive(:perform_later).with(
            content,
            kind_of(Repository),
            Content::DEFAULT_PUBLISH_METHOD
          )

          subject
        end

        context 'listserv ids included' do
          let(:listservs) {
            FactoryGirl.create_list(:listserv, 2)
          }
          before do
            content_params.merge!(listserv_ids: listservs.map(&:id))
          end

          it 'promotes to listservs' do
            expect(PromoteContentToListservs).to receive(:call).with(
              content,
              @consumer_app,
              request.remote_ip,
              *listservs
            )

            subject
          end
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
