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
end
