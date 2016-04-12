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
          published_at: Time.zone.now
        }
      end

      it 'should create a content record' do
        expect{subject}.to change{Content.count}.by 1
      end
    end

    context 'without an organization_id specified' do
      let(:post_params) do
        {
          title: 'blerb',
          content: Faker::Lorem.paragraph,
          organization_id: nil,
          published_at: Time.zone.now
        }
      end
      
      it 'should not create content' do
        expect{subject}.to_not change{Content.count}
      end

      it 'should respond with errors' do
        subject
        expect(response_json['errors']).to be_present
      end
    end
  end

  describe 'PUT /api/v3/news/:id' do
    before do
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      @org = FactoryGirl.create :organization, can_publish_news: true
      @content = FactoryGirl.create :content, organization: @org
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
      @content = Content.find(response_json['news']['id'])
      # add an image to the draft
      post '/api/v3/images', {
        image: {
          content_id: @content.id,
          # note -- have to specify the full path of the fixture in request specs
          # because of a bug in rspec-rails (https://github.com/rspec/rspec-rails/issues/1554)
          image: fixture_file_upload("#{::Rails.root}/spec/fixtures/photo.jpg", 'image/jpg'),
          primary: true
        }
      }
      @img = Image.find(response_json['image']['id'])
    end

    it 'should associate the image with the content' do
      subject
      expect(@content.images).to match_array([@img])
    end
  end
end
