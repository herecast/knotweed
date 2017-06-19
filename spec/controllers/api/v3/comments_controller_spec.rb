require 'spec_helper'
require 'json'

describe Api::V3::CommentsController, :type => :controller do

  describe 'GET index' do
    it 'should fail without content_id' do
      get :index, format: :json
      expect(response.status).to eql 404
    end

    describe 'given content_id' do
      before do
        user = FactoryGirl.create :user
        @content = FactoryGirl.create :content, created_by: user
        @comment = FactoryGirl.create :comment
        @comment.content.update_attribute :parent_id, @content.id
      end

      subject { get :index, format: :json, content_id: @content.id }

      it 'should return the coments associated' do
        subject
        expect(assigns(:comments)).to eq([@comment.content])
      end

      context 'when the root content is a talk item' do
        let(:talk_cat) { FactoryGirl.create :content_category, name: 'talk_of_the_town' }
        before do
          user = FactoryGirl.create :user
          @content = FactoryGirl.create :content, content_category: talk_cat, created_by: user
          @comment_content = FactoryGirl.create :content, content_category: talk_cat
          @talk_comment = FactoryGirl.create :comment, content: @comment_content
          @talk_comment.content.update_attributes(parent_id: @content.id, root_content_category_id: talk_cat)
        end

        it 'returns the correct comments for the root content' do
          subject
          expect(assigns(:comments)).to eq([@talk_comment.content])
        end
      end
    end

    describe 'nested comments' do
      before do
        @event = FactoryGirl.create :event
        @comment1 = FactoryGirl.create :comment
        @comment1.content.update_attributes(parent_id: @event.content.id,
                                            pubdate: 2.hours.ago,
                                            created_by: FactoryGirl.create(:user))
        @comment2 = FactoryGirl.create :comment
        @comment2.content.update_attributes(parent_id: @comment1.content.id,
                                            pubdate: 1.hour.ago,
                                            created_by: FactoryGirl.create(:user))
        @comment3 = FactoryGirl.create :comment
        @comment3.content.update_attributes(parent_id: @comment1.content.id,
                                            pubdate: Time.current,
                                            created_by: FactoryGirl.create(:user))
      end

      subject! { get :index, format: :json, content_id: @event.content.id }

      it 'should return the results flattened and ordered' do
        # pubdate time varies based on when the Factory creates them, so need to order first
        # to match what the controller does
        comments = [@comment3, @comment2, @comment1].map{ |c| comment_format(c) }
        expected = {comments: comments}.stringify_keys
        expect(JSON.parse(response.body)).to eq(expected)
      end
    end

    describe 'ordered by pubdate DESC' do
      before do
        @event = FactoryGirl.create :event
        @comment1 = FactoryGirl.create :comment, pubdate: Time.parse('2014-01-01')
        @comment1.content.update created_by: FactoryGirl.create(:user),
          parent: @event.content
        @comment2 = FactoryGirl.create :comment, pubdate: Time.parse('2014-02-01')
        @comment2.content.update created_by: FactoryGirl.create(:user),
          parent: @comment1.content
        @comment3 = FactoryGirl.create :comment, pubdate: Time.parse('2014-03-01')
        @comment3.content.update parent: @comment2.content,
          created_by: FactoryGirl.create(:user)
      end

      subject! { get :index, format: :json, content_id: @event.content.id }

      it 'should return ordered results' do
        expected = {comments: [comment_format(@comment3), comment_format(@comment2), comment_format(@comment1)]}.stringify_keys
        expect(JSON.parse(response.body)).to eq(expected)
      end
    end

    describe 'when avatar is present' do
      before do
        google_logo_stub
        user = FactoryGirl.create :user, remote_avatar_url:  "https://www.google.com/images/srpr/logo11w.png"
        @content = FactoryGirl.create :content
        @comment = FactoryGirl.create :comment
        @comment.content.update parent_id: @content.id, created_by: user
      end

      subject! { get :index, format: :json, content_id: @content.id }

      it 'should include avatar url in the response' do
        expect(JSON.parse(response.body)).to eq({comments: [comment_format(@comment)]}.stringify_keys)
      end
    end

  end

  describe 'POST create' do
    before do
      @event = FactoryGirl.create :event
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    subject { post :create, comment: { content: 'fake', parent_content_id: @event.content.id } }

    context 'should not allow creation if user unauthorized' do
      before { api_authenticate success: false }
      it do
        subject
        expect(response.code).to eq('401')
        expect(Comment.count).to eq(0)
      end
    end

    context 'with consumer_app / repository' do
      before do
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        api_authenticate user: @user, consumer_app: @consumer_app
        stub_request(:post, /.*/)
      end

      it 'should queue the content to be published' do
        expect{subject}.to have_enqueued_job(PublishContentJob)
      end
    end

    it 'should automatically set organization to DailyUV' do
      subject
      expect(response.code).to eq('201')
      expect(assigns(:comment).content.parent).to eq(@event.content)
      expect(assigns(:comment).organization.name).to eq('DailyUV')
    end
  end

  private

  def comment_format(comment)
    # r means results
    r = {}
    r[:id] = comment.channel.id
    r[:content] = comment.sanitized_content
    r[:user_id] = comment.created_by.id
    r[:user_name] = comment.created_by.name
    r[:user_image_url] = comment.created_by.try(:avatar).try(:url)
    r[:published_at] = comment.pubdate.iso8601
    r[:parent_content_id] = comment.parent_id
    r[:content_id] = comment.content.id
    r.stringify_keys
  end

end
