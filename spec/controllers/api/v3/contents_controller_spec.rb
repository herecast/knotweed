require 'spec_helper'

describe Api::V3::ContentsController, :type => :controller do
  before do
    @repo = FactoryGirl.create :repository
    @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
    @org = FactoryGirl.create :organization
    @consumer_app.organizations = [@org]
  end

  describe 'GET related_promotion' do
    before do
      @content = FactoryGirl.create :content
      @related_content = FactoryGirl.create(:content)
      allow_any_instance_of(Promotion).to receive(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promo
      # avoid making calls to repo
      allow_any_instance_of(DspService).to receive(:query_promo_similarity_index).and_return([])
    end

    subject { get :related_promotion, format: :json, 
              id: @content.id, consumer_app_uri: @consumer_app.uri }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'should increment the load count of the banner' do
      expect{subject}.to change{@pb.reload.load_count}.by(1)
    end

    context 'with banner_ad_override' do
      before do
        @promo2 = FactoryGirl.create :promotion, content: FactoryGirl.create(:content)
        @pb2 = FactoryGirl.create :promotion_banner, promotion: @promo2
        @content.update_attribute :banner_ad_override, @promo2.id
      end

      it 'should respond with the banner specified by the banner_ad_override' do
        subject
        expect(assigns(:banner)).to eq @pb2
      end
    end

  end

  describe 'GET similar_content' do
    before do
      ENV['sim_stack_categories'] = nil
      @content = FactoryGirl.create(:content)
      @content_id = @content.id
      # note, similar content is filtered by organization so we need to ensure this has
      # a organization that exists in the consumer app's list.
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @sim_content1 = FactoryGirl.create :content, organization: @org
      @sim_content2 = FactoryGirl.create :content, organization: @org,
        content_category: @market_cat
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
        expect(assigns(:contents)).to eq([@sim_content2])
      end
    end

    it 'responds with relation of similar content' do
      subject
      expect(assigns(:contents)).to match_array([@sim_content1, @sim_content2])
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
        @root_content = FactoryGirl.create :content, organization: @org
        @content = FactoryGirl.create :content, organization: @org
        other_content = FactoryGirl.create :content, organization: @org
        event = FactoryGirl.create :event, skip_event_instance: true, content: @content
        other_event = FactoryGirl.create :event, skip_event_instance: true, content: other_content
        FactoryGirl.create :event_instance, event: other_event, start_date: 1.week.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.week.from_now
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.from_now
        @sim_content = [@content, other_content]
        allow_any_instance_of(Content).to receive(:similar_content).with(@repo, 20).and_return(@sim_content)
      end

      subject { get :similar_content, format: :json, id: @root_content.id, consumer_app_uri: @consumer_app.uri }

      it 'should response with events that have instances in the future' do
        subject
        expect(assigns(:contents)).to eq [@content]
      end
    end

    context 'for sponsored_content' do
      before do
        @content.content_category_id = FactoryGirl.create(:content_category, name: 'sponsored_content').id
        @some_similar_contents = FactoryGirl.create_list(:content, 3, organization: @org)
        @content.similar_content_overrides = @some_similar_contents.map{|c| c.id}
        @content.save
      end

      it 'should respond with the contents defined by similar_content_overrides' do
        subject
        expect(assigns(:contents)).to match_array(@some_similar_contents)
      end
    end
  end

  describe 'POST /contents/:id/moderate' do
     
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
      
      api_authenticate user: @user
    end

    it 'should queue flag notification email' do
      mailer_count = ActionMailer::Base.deliveries.count
      post :moderate, id: @content.id, flag_type: 'Inappropriate'
      expect(ActionMailer::Base.deliveries.count).to eq(mailer_count + 1)
    end

  end

  describe 'GET dashboard' do
    subject { get :dashboard }

    context 'not signed in' do
      it 'has 401 status code' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'signed in' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      it 'has 200 status code' do
        subject
        expect(response.code).to eq('200')
      end

      describe 'filtering by organization_id' do
        before do
          @news_cat = FactoryGirl.create :content_category, name: 'news'
        end

        context 'that user is not a manager of' do
          before do
            @org = FactoryGirl.create :organization
            @org_contents = FactoryGirl.create_list :content, 3
          end

          subject { get :dashboard, organization_id: @org.id }

          it 'should not return the organization\'s contents' do
            subject
            expect(assigns(:contents)).not_to match_array(@org_contents)
          end
        end

        context 'that user is manager for' do
          before do
            @org = FactoryGirl.create :organization
            @org_contents = FactoryGirl.create_list :content, 3,
              content_category_id: @news_cat.id, organization: @org
            @user.add_role :manager, @org
          end

          subject { get :dashboard, organization_id: @org.id }

          it 'should return contents that belongs to the organization' do
            subject
            expect(assigns(:contents)).to match_array(@org_contents)
          end
        end

        context 'that user is manager of parent of' do
          before do
            @parent = FactoryGirl.create :organization
            @child = FactoryGirl.create :organization, parent: @parent
            @user.add_role :manager, @parent
            @contents = FactoryGirl.create_list :content, 3,
              content_category_id: @news_cat.id, organization: @child
          end

          subject { get :dashboard, organization_id: @child.id }

          it 'should return contents that belong to the organization' do
            subject
            expect(assigns(:contents)).to match_array(@contents)
          end
        end
      end

      context 'with the user owning some content' do
        before do
          @news_cat = FactoryGirl.create :content_category, name: 'news'
          @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
          @market_cat = FactoryGirl.create :content_category, name: 'market'
          @event_cat = FactoryGirl.create :content_category, name: 'event'

          #@event = FactoryGirl.create :event, content_category: @event_cat
          FactoryGirl.create_list :content, 5, 
            content_category: @news_cat, 
            published: true
          FactoryGirl.create_list :content, 5, 
            content_category: @market_cat, 
            published: true
          FactoryGirl.create_list :content, 5,
            content_category: @talk_cat,
            published: true
          event_conts = FactoryGirl.create_list :content, 5, 
            content_category: @event_cat,
            channel_type: 'Event',
            published: true
          event_conts.each do |ec|
            FactoryGirl.create :event, content: ec
          end
          Content.update_all created_by: @user
        end

        it 'responds with the user\'s content' do
          not_user_content = FactoryGirl.create :content
          # created_by automatically set by auditable mixin
          not_user_content.update_attribute(:created_by, nil)
          subject
          all_content = assigns(:contents) 
          user_content_only = all_content.select{|c| c.created_by == @user} 
          expect(all_content).to_not include(not_user_content) 
          expect(all_content.collect(&:id)).to eql user_content_only.collect(&:id)
        end

        describe 'sorting' do
          it 'allows sorting by specified parameters (pubdate)' do
            content = Content.last
            content.update_attribute(:pubdate, Date.tomorrow)

            get :dashboard, sort: 'pubdate DESC'
            expect(assigns(:contents).first).to eq(content)
          end

          describe 'by channel_type ASC' do
            it 'first item should be event' do
              get :dashboard, format: :json, sort: 'channel_type ASC'
              expect(assigns(:contents).first.root_content_category_id).to be @event_cat.id
            end
          end

          describe 'by channel_type DESC' do
            it 'first item should be talk' do
              get :dashboard, format: :json, sort: 'channel_type DESC'
              expect(assigns(:contents).first.root_content_category_id).to be @talk_cat.id
            end
          end
        end

        describe 'category children' do
          before do
            @child_of_news = FactoryGirl.create :content_category, name: 'child', parent: @news_cat
            @c = FactoryGirl.create :content, content_category: @child_of_news,
              published: true
            @c.update_attribute(:created_by, @user)
          end

          subject { get :dashboard, channel_type: 'news' }

          it 'should return content belonging to news\' child category' do
            subject
            expect(assigns(:contents)).to include(@c)
          end
        end

        context 'allow filtering by news' do
          before do
            get :dashboard, channel_type: 'news'
          end

          it 'should return only news content'  do
            category_ids = assigns(:contents).collect(&:root_content_category_id)
            expect(category_ids.uniq.count).to eq 1
            expect(category_ids.uniq.first).to eq @news_cat.id 
          end
        end 
        context 'allow filtering by events' do
          before do
            get :dashboard, channel_type: 'events'
          end

          it 'should return only events content' do
            category_ids = assigns(:contents).collect(&:root_content_category_id)
            expect(category_ids.uniq.count).to eq 1
            expect(category_ids.uniq.first).to eq @event_cat.id 
          end
        end

        context 'allow filtering by talk' do
          before do
            get :dashboard, channel_type: 'talk'
          end

          it 'should return only talk content' do
            category_ids = assigns(:contents).collect(&:root_content_category_id)
            expect(category_ids.uniq.count).to eq 1
            expect(category_ids.uniq.first).to eq @talk_cat.id 
          end
        end

        context 'allow filtering by market' do
          before do
            get :dashboard, channel_type: 'market'
          end

          it 'should return only market content' do
            category_ids = assigns(:contents).collect(&:root_content_category_id)
            expect(category_ids.uniq.count).to eq 1
            expect(category_ids.uniq.first).to eq @market_cat.id 
          end
        end
      end
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
