require 'spec_helper'

describe 'News Endpoints', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'POST /api/v3/news' do
    before do
      @org = FactoryGirl.create :organization, can_publish_news: true
    end

    subject { post '/api/v3/news', { news: post_params }, auth_headers }

    context 'with valid params' do
      let(:post_params) do
        {
          title: 'Title',
          subtitle: 'Subtitle',
          content: Faker::Lorem.paragraph,
          organization_id: @org.id,
          published_at: Time.current,
          author_name: 'Some String Not The User'
        }
      end

      it 'should create a content record' do
        expect{subject}.to change{Content.count}.by 1
      end
    end

    describe 'author_name' do
      let(:post_params) do
        {
          title: 'Title',
          organization_id: @org.id,
          author_name: author_name
        }
      end
      before { post '/api/v3/news', { news: post_params }, auth_headers }
      subject { Content.last }

      context 'when it\'s the same as the user\'s name' do
        let(:author_name) { user.name }

        it 'should persist authors as blank' do
          expect(subject.authors).to be_blank
        end

        it 'should set authors_is_created_by to true' do
          expect(subject.authors_is_created_by).to be true
        end
      end

      context 'when author_name is something different' do
        let(:author_name) { Faker::Name.name }

        it 'should persist the author_name as authors' do
          expect(subject.authors).to eq author_name
        end

        it 'should leave authors_is_created_by false' do
          expect(subject.authors_is_created_by).to be false
        end
      end

      context 'when author_name is blank' do
        let(:author_name) { '' }

        it 'should persist the blank author name' do
          expect(subject.authors).to be_blank
        end

        it 'should leave authors_is_created_by false' do
          expect(subject.authors_is_created_by).to be false
        end
      end
    end

    describe 'saving a draft' do
      let(:post_params) do
        {
          title: 'My Title',
          content: 'Who cares',
          published_at: nil
        }
      end

      it 'should create a content record' do
        expect{subject}.to change{Content.count}.by 1
      end
    end
    
    describe "content sanitization" do
    
      describe 'in-content img with style attributes' do
        let(:post_params) do
          {
            title: 'My Title',
            content: 'Who cares <img style="width: 50%; float: left;" src="http://go.test/this.jpg">',
            published_at: nil
          }
        end
        
        it "does not strip out style attribute" do
          subject
          response_content = response_json[:news][:content]
          expect(response_content).to eql post_params[:content]
        end
      end
    end
  end

  describe 'PUT /api/v3/news/:id' do
    before do
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      @org = FactoryGirl.create :organization, can_publish_news: true
      @content = FactoryGirl.create :content, organization: @org, pubdate: nil
    end

    let(:put_params) do
      {
        title: 'New Different Title'
      }
    end

    subject { put "/api/v3/news/#{@content.id}", { news: put_params }, auth_headers }

    it 'should update the content' do
      expect{subject}.to change{@content.reload.title}.to put_params[:title]
    end

    describe 'author_name' do
      context 'with authors_is_created_by true at first' do
        before do
          @content.authors = nil
          @content.authors_is_created_by = true
          @content.save
        end

        let(:put_params) do
          {
            title: 'New Different Title',
            author_name: Faker::Name.name
          }
        end

        it 'should set `authors_is_created_by` to false' do
          expect{subject}.to change{@content.reload.authors_is_created_by}.to false
        end
      end
    end

    describe 'scheduling a draft for publishing' do
      let(:put_params) do
        {
          published_at: 2.months.from_now
        }
      end

      it 'should update the content pubdate' do
        expect{subject}.to change{@content.reload.pubdate}
      end
    end

    describe 'unscheduling a previously scheduled draft' do
      before do
        @content.update_attribute :pubdate, 2.months.from_now
      end

      let(:put_params) do
        {
          published_at: nil
        }
      end

      it 'should unset the pubdate and make the content a draft' do
        expect{subject}.to change{@content.reload.pubdate}.to nil
      end
    end

    describe 'unpublishing published content' do
      before do
        @content.update_attribute :pubdate, 1.week.ago
      end

      let(:put_params) do
        {
          published_at: nil
        }
      end

      it 'should not succeed' do
        expect{subject}.to_not change{@content.reload.pubdate}
      end
    end

    describe 'modifying published content' do
      before do
        @content.update_attribute :pubdate, 1.week.ago
      end

      let(:put_params) do
        {
          published_at: @content.pubdate,
          title: 'New Title For This Content'
        }
      end

      it 'should update the content' do
        expect{subject}.to change{@content.reload.title}
      end
    end

    context 'without an organization specified' do
      before { @content.update_attribute :organization_id, nil }

      context 'with pubdate' do
        let(:put_params) do
          {
            title: 'blerb',
            content: Faker::Lorem.paragraph,
            organization_id: nil,
            published_at: Time.current
          }
        end
      
        it 'should not update content' do
          expect{subject}.to_not change{@content.reload.title}
        end

        it 'should respond with errors' do
          subject
          expect(response_json[:errors]).to be_present
        end
      end

      context 'without pubdate' do
        let(:put_params) do
          {
            title: 'blerb',
            content: Faker::Lorem.paragraph,
            organization_id: nil,
            published_at: nil
          }
        end

        it 'should update the content' do
          expect{subject}.to change{@content.reload.title}.to put_params[:title]
        end
      end
    end
  end

  describe 'creating a news object and associating images' do
    before do
      @org = FactoryGirl.create :organization, can_publish_news: true
    end

    subject do
      # create a draft content
      post '/api/v3/news', {
        news: {
          title: Faker::Lorem.sentence,
          organization_id: @org.id,
          published_at: nil
        }
      }, auth_headers
      @content = Content.find(response_json[:news][:id])
      # add an image to the draft
      post '/api/v3/images', {
        image: {
          content_id: @content.id,
          # note -- have to specify the full path of the fixture in request specs
          # because of a bug in rspec-rails (https://github.com/rspec/rspec-rails/issues/1554)
          image: fixture_file_upload("#{::Rails.root}/spec/fixtures/photo.jpg", 'image/jpg'),
          primary: true
        }
      }, auth_headers
      @img = Image.find(response_json[:image][:id])
    end

    it 'should associate the image with the content' do
      subject
      expect(@content.images).to match_array([@img])
    end
  end

  describe 'DELETE /api/v3/news' do
    let!(:news_cat) { FactoryGirl.create :content_category, name: 'news'}
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }

    let!(:news) { FactoryGirl.create :content, created_by: user, organization: org, content_category: news_cat }

    it 'sets #deleted_at' do
      expect {
        delete "/api/v3/news/#{news.id}", {}, headers.merge(auth_headers)
      }.to change {
        news.reload.deleted_at
      }
      expect(news.deleted_at).to be_a Time
    end

    context 'not signed in' do
      it 'returns unauthenticated' do
        delete "/api/v3/news/#{news.id}", {}, headers
        expect(response.status).to eql 401
      end

      it 'does not set #deleted_at' do
        expect {
          delete "/api/v3/news/#{news.id}", {}, headers
        }.to_not change{ news.reload.deleted_at }
      end
    end

    context 'not authorized to destroy' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:destroy, news).and_return false
      end

      it 'returns unauthorized' do
        delete "/api/v3/news/#{news.id}", {}, headers.merge(auth_headers)
        expect(response.status).to eql 403
      end

      it 'does not set #deleted_at' do
        expect {
          delete "/api/v3/news/#{news.id}", {}, headers.merge(auth_headers)
        }.to_not change{ news.reload.deleted_at }
      end

    end

  end

  describe 'GET /api/v3/news' do
    let!(:news_cat) { FactoryGirl.create :content_category, name: 'news'}
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }

    let!(:news) { FactoryGirl.create :content, created_by: user, organization: org, published: true, content_category: news_cat }
    let!(:deleted_news) { FactoryGirl.create :content, created_by: user, organization: org, published: true, content_category: news_cat, deleted_at: Time.current }
    
    before { index }

    it 'returns news' do
      get '/api/v3/news', {}, headers
      ids = response_json[:news].map{|i| i[:id]}

      expect(ids).to include news.id
    end

    it 'does not return deleted news' do
      get '/api/v3/news', {}, headers
      ids = response_json[:news].map{|i| i[:id]}

      expect(ids).to_not include deleted_news.id

    end

  end

  describe 'GET /api/v3/news/:id' do
    let(:news_cat) { ContentCategory.find_or_create_by name: 'news' }
    context 'news has been deleted' do
      let!(:deleted_news) { FactoryGirl.create :content,
                           content_category: news_cat,
                           created_by: user,
                           published: true,
                           deleted_at: Time.current}

      it 'does not return deleted content' do
        get "/api/v3/news/#{deleted_news.id}"

        expect(response.status).to eql 404
      end
    end

  end
end
