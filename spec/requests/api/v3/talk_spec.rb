require 'rails_helper'

describe 'Talk', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/talk/:id' do
    context 'record exists' do
      let(:record) {
        FactoryGirl.create(:content, :talk, :published, {
          created_by: FactoryGirl.create(:user)
        })
      }

      context 'not authenticated' do
        subject { get "/api/v3/talk/#{record.id}" }

        it 'returns 401' do
          expect(subject).to eql 401
        end

        context 'talk is located to "Upper Valley" (default location/region)' do
          let(:default_location) {
            FactoryGirl.create :location, :default
          }
          before do
            record.update locations: [default_location]
          end

          it 'returns 200' do
            expect(subject).to eql 200
          end

          it 'returns record json' do
            subject
            expect(response.body).to include_json(
              talk: {
                id: record.id,
                title: record.title,
                content: record.sanitized_content,
                content_id: record.id,
                image_url: an_instance_of(String).or(be_nil),
                user_count: a_kind_of(Integer).or(be_nil),
                author_name: an_instance_of(String),
                author_image_url: an_instance_of(String).or(be_nil),
                image_width: a_kind_of(Integer).or(be_nil),
                image_height: a_kind_of(Integer).or(be_nil),
                image_file_extension: an_instance_of(String).or(be_nil),
                published_at: record.pubdate.iso8601,
                view_count: a_kind_of(Integer),
                commenter_count: a_kind_of(Integer),
                comment_count: a_kind_of(Integer),
                parent_content_id: record.parent_id,
                parent_content_type: an_instance_of(String).or(be_nil),
                author_email: record.created_by.email,
                created_at: record.created_at.iso8601,
                updated_at: record.updated_at.iso8601,
                content_locations: record.content_locations.map do |cl|
                  cl.attributes.slice(:id, :location_type, :location_id)
                end
              }
            )
          end
        end
      end
    end
  end

  describe 'POST /api/v3/talk' do
    context "with valid request data" do
      before do
        ContentCategory.create(name: :talk_of_the_town)
      end

      let(:valid_params) {
        {
          title: 'Test',
          content: 'Body'
        }
      }

      subject{ post("/api/v3/talk", {talk: valid_params}, auth_headers) }

      it 'responds with 201' do
        subject
        expect(response.status).to eql 201
      end

      it 'creates a record' do
        expect{ subject }.to change{
          Comment.count
        }.by(1)
      end

      it 'returns a content_id in json' do
        # this is needed by listserv workflow
        subject
        expect(response_json[:talk][:content_id]).to eql Comment.last.content.id
      end
    end
  end
end
