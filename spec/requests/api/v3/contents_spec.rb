require 'spec_helper'


def content_response_schema(record)
  {
    content: {
      author_id: record.created_by.id,
      author_name: record.created_by.name,
      avatar_url: record.created_by.avatar_url,
      biz_feed_public: record.biz_feed_public,
      campaign_end: record.try(:promotions).try(:first).try(:promotable).try(:campaign_end),
      campaign_start: record.try(:promotions).try(:first).try(:promotable).try(:campaign_start),
      click_count: nil,
      comment_count: 0,
      commenter_count: 0,
      # contact_email is only returned for event and market content
      contact_email: ([:market, :event].include?(record.content_type) ? (record.channel.try(:contact_email) || record.authoremail) : nil),
      contact_phone: record.channel.try(:contact_phone),
      content: record.sanitized_content,
      content_origin: Content::UGC_ORIGIN.downcase,
      content_type: record.content_type.to_s,
      cost: record.channel.try(:cost),
      cost_type: record.channel.try(:cost_type),
      created_at: record.created_at.iso8601,
      embedded_ad: record.embedded_ad?,
      ends_at: record.channel.try(:next_or_first_instance).try(:end_date).try(:iso8601),
      event_url: record.channel.try(:event_url),
      event_instance_id: record.channel.try(:next_or_first_instance).try(:id),

      # Problems with a matching against nested array with include_json
      #event_instances: [],

      id: record.id,
      images: [],
      image_url: nil,
      organization_biz_feed_active: record.organization&.biz_feed_active,
      organization_id: record.organization&.id,
      organization_name: record.organization&.name,
      organization_profile_image_url: record.organization&.profile_image_url,
      parent_content_id: record.parent_id,
      parent_content_type: record.parent.try(:content_type),
      parent_event_instance_id: record.parent.try(:channel).try(:event_instances).try(:first).try(:id),
      promote_radius: record.promote_radius,
      published_at: record.pubdate&.iso8601,
      redirect_url: record.promotions.try(:first).try(:promotable).try(:redirect_url),
      registration_deadline: record.channel.try(:registration_deadline),

      # Problems with a matching against nested array with include_json
      #schedules: [],

      sold: record.channel.try(:sold),
      split_content: nil,
      starts_at: record.channel.try(:next_or_first_instance).try(:start_date).try(:iso8601),
      subtitle: record.subtitle,
      sunset_date: record.sunset_date.try(:iso8601),
      title: record.title,
      location_id: record.base_locations.first.try(:slug),

      # random failures due to database time vs rails time
#      updated_at: record.updated_at.iso8601,

      venue_address: record.channel.try(:venue).try(:address),
      venue_city: record.channel.try(:venue).try(:city),
      venue_name: record.channel.try(:venue).try(:name),
      venue_state: record.channel.try(:venue).try(:state),
      venue_url: record.channel.try(:venue).try(:venue_url),
      venue_zip: record.channel.try(:venue).try(:zip),
      view_count: 0
    }
  }
end

describe 'Contents Endpoints', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'GET /api/v3/contents/:id' do
    let(:org) { FactoryGirl.create :organization }
    let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [org] }
    let(:headers) { {'ACCEPT' => 'application/json',
                     'Consumer-App-Uri' => consumer_app.uri
                  } }
    let(:content) { FactoryGirl.create :content, organization: org }

    context "when no requesting app" do
      subject { get "/api/v3/contents/#{content.id}" }

      it 'does not return content' do
        subject
        expect(response_json).to eq({})
      end
    end

    context "when appropriate requesting app" do
      subject { get "/api/v3/contents/#{content.id}", {}, headers }

      it "returns content record" do
        subject
        expect(response_json[:content]).not_to be nil
      end

      it 'matches the expect json schema' do
        subject
        expect(response.body).to include_json(content_response_schema(content))
      end

      context "when content organization has embedded_ad: true" do
        let(:organization) { FactoryGirl.create :organization, embedded_ad: true }
        let(:content) { FactoryGirl.create :content, :news, organization: organization }

        before { consumer_app.organizations << organization }

        it 'returns record with split content' do
          subject
          response_split_content = response_json[:content][:split_content]
          expect(response_split_content.key?(:head)).to be true
          expect(response_split_content.key?(:head)).to be true
        end
      end
    end

    describe 'when content requested is of listserv origin' do
      let(:listserv_org) {
        FactoryGirl.create(:organization,
          id: Organization::LISTSERV_ORG_ID
        )
      }
      before do
        consumer_app.update organizations: [listserv_org]
        content.update organization: listserv_org
      end

      subject { get "/api/v3/contents/#{content.id}", {}, headers }

      context 'user is not signed in' do
        it 'returns a 401 status' do
          subject
          expect(response.code).to eql "401"
        end
      end

      context 'user is signed in' do
        let(:user) { FactoryGirl.create :user }
        let(:auth_headers) { auth_headers_for(user) }
        before do
          headers.merge! auth_headers
        end

        it 'returns a 200 status' do
          subject
          expect(response.code).to eql "200"
        end
      end
    end
  end

  describe 'GET /api/v3/contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content, created_by: user
    end

    context "when no start_date or end_date" do
      subject { get "/api/v3/contents/#{@content.id}/metrics", {}, auth_headers }

      it "returns bad_request status" do
        subject
        expect(response.status).to eql 400
      end
    end

    context "when start_date and end_date present" do
      before do
        date_range = (2.days.ago.to_date..Date.current)
        @start_date = date_range.first.to_s
        @end_date = date_range.last.to_s
        date_range.each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      let(:expected_response) {{
        id: @content.id,
        title: @content.title,
        image_url: @content.primary_image&.image_url,
        view_count: 0,
        comment_count: 0,
        comments: [],
        promo_click_thru_count: @content.banner_click_count,
        daily_view_counts: @content.content_reports.map{ |cr|
          cr.view_count_hash
        },
        daily_promo_click_thru_counts: @content.content_reports.map{ |cr|
          cr.banner_click_hash
        }
      }}

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", {}, auth_headers }

      it 'returns daily view counts' do
        subject
        expect(response_json[:content_metrics]).to include expected_response
      end
    end

    context 'Given 40 days of metrics data exist;' do
      before do
        date_range = (40.days.ago.to_date..Date.current)
        @start_date = date_range.first.to_s
        @end_date = date_range.last.to_s
        date_range.each do |date|
          FactoryGirl.create(:content_report, content: @content, report_date: date)
        end
      end

      subject { get "/api/v3/contents/#{@content.id}/metrics?start_date=#{@start_date}&end_date=#{@end_date}", {}, auth_headers }

      it 'returns all daily_view_counts by default' do
        subject
        view_counts = response_json[:content_metrics][:daily_view_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'returns all daily_promo_click_thru_counts by default' do
        subject
        view_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
        expect(view_counts.count).to eql @content.content_reports.count
      end

      it 'orders daily_view_counts ASC on report_date' do
        subject
        view_counts = response_json[:content_metrics][:daily_view_counts]
        report_dates = view_counts.map{|v| DateTime.parse(v[:report_date]).to_date}
        sorted_dates = report_dates.sort
        expect(report_dates).to eql sorted_dates
      end

      context "when days are missing reports" do
        before do
          ContentReport.all[10..12].each { |cr| cr.delete }
          @expected_nuber_of_reports = 41
        end

        it "returns expected number of daily reports" do
          subject
          view_counts = response_json[:content_metrics][:daily_view_counts]
          expect(view_counts.count).to eql @expected_nuber_of_reports
          click_counts = response_json[:content_metrics][:daily_promo_click_thru_counts]
          expect(click_counts.count).to eql @expected_nuber_of_reports
        end
      end
    end
  end

  describe 'UGC' do
    let(:headers) {
      {
        "ACCEPT" => 'appliction/json'
      }
    }
    let(:request_body) {
      {}
    }

    describe 'POST /api/v3/contents' do
      subject {
        post '/api/v3/contents', request_body, headers
      }
      context 'without authentication' do
        it 'returns 401' do
          subject
          expect(response.status).to eql 401
        end
      end

      context 'with authentication' do
        let(:user) do
          FactoryGirl.create :user
        end

        before do
          headers.merge! auth_headers_for(user)
        end

        describe 'unknown content type' do
          let(:params) {
            {
              content_type: 'blog_post',
              title: 'not a valid content type',
            }
          }

          before do
            request_body.merge!(content: params)
          end

          it 'returns a 422 error' do
            subject
            expect(response.status).to eql 422
            expect(response_json[:error]).to eql "unknown content type"
          end
        end

        describe 'news content' do
          context 'valid params' do
            let(:valid_news_params) {
              {
                content_type: 'news',
                title: "A distinguished article",
                content: "<p>Once upon a time...</p>",
                author_name: 'Fred',
                organization_id: FactoryGirl.create(:organization,
                  can_publish_news: true
                ).id,
              }
            }

            before do
              request_body.merge!(content: valid_news_params)
            end

            it 'return 201 status' do
              subject
              expect(response.status).to eql 201
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(Content.last).deep_merge(
                  content: {
                    title: valid_news_params[:title],
                    content: valid_news_params[:content],
                    author_name: "Fred",
                    organization_id: valid_news_params[:organization_id]
                  }
                )
              )
            end

            describe 'author_name' do
              let(:author_name) {""}
              before do
                valid_news_params.merge!(author_name: author_name)
                subject
              end

              context 'when it\'s the same as the user\'s name' do
                let(:author_name) { user.name }

                it 'should persist authors as blank' do
                  expect(Content.last.authors).to be_blank
                end

                it 'should set authors_is_created_by to true' do
                  expect(Content.last.authors_is_created_by).to be true
                end
              end

              context 'when author_name is something different' do
                let(:author_name) { Faker::Name.name }

                it 'should persist the author_name as authors' do
                  expect(Content.last.authors).to eq author_name
                end

                it 'should leave authors_is_created_by false' do
                  expect(Content.last.authors_is_created_by).to be false
                end
              end

              context 'when author_name is blank' do
                let(:author_name) { '' }

                it 'should persist the blank author name' do
                  expect(Content.last.authors).to be_blank
                end

                it 'should leave authors_is_created_by false' do
                  expect(Content.last.authors_is_created_by).to be false
                end
              end
            end

            describe 'saving a draft' do
              before do
                valid_news_params[:published_at] = nil
              end

              it 'should create a draft content record' do
                expect{subject}.to change{Content.count}.by 1
                expect(Content.last.pubdate).to be_nil
              end
            end

            describe "content sanitization" do

              describe 'in-content img with style attributes' do
                before do
                  valid_news_params[:content] = 'Who cares <img style="width: 50%; float: left;" src="http://go.test/this.jpg">'
                end

                it "does not strip out style attribute" do
                  subject
                  response_content = response_json[:content][:content]
                  expect(response_content).to eql valid_news_params[:content]
                end
              end
            end
          end
        end

        describe 'talk content' do
          context 'valid params' do
            let(:valid_talk_params) {
              {
                content_type: 'talk',
                title: "TFK",
                content: "<p>Oxygen: Inhale</p>",
                promote_radius: 10,
                location_id: FactoryGirl.create(:location).slug
              }
            }

            before do
              request_body.merge!(content: valid_talk_params)
            end

            it 'return 201 status' do
              subject
              expect(response.status).to eql 201
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(Content.last).deep_merge(
                  content: {
                    title: valid_talk_params[:title],
                    content: valid_talk_params[:content]
                  }
                )
              )
            end
          end
        end

        describe 'market content' do
          context 'valid params' do
            let(:organization) do
              FactoryGirl.create(:organization)
            end

            let(:valid_market_params) {
              {
                contact_email: 'test@test.com',
                contact_phone: '000-000-0000',
                content: "<p>Oxygen: Inhale</p>",
                content_type: 'market',
                cost: "$10",
                organization_id: organization.id,
                promote_radius: 10,
                title: "TFK",
                sold: false,
                ugc_job: 'Sell or give something away',
                location_id: FactoryGirl.create(:location).slug
              }
            }

            before do
              request_body.merge!(content: valid_market_params)
            end

            it 'return 201 status' do
              subject
              expect(response.status).to eql 201
            end

            it 'returns json respresenation' do
              Timecop.freeze do
                subject
                expect(response.body).to include_json(
                  content_response_schema(Content.last).deep_merge(
                    content: {
                      contact_email: valid_market_params[:contact_email],
                      contact_phone: valid_market_params[:contact_phone],
                      content: valid_market_params[:content],
                      cost: valid_market_params[:cost],
                      sold: valid_market_params[:sold],
                      title: valid_market_params[:title]
                    }
                  )
                )
              end
            end
          end
        end

        describe 'event content' do
          context 'valid params' do
            let(:business_location) {
              FactoryGirl.create(:business_location)
            }

            let(:valid_event_params) {
              {
                content_type: 'event',
                title: "Concert",
                content: "<p>Tickets for sale a the doors</p>",
                cost: "$10",
                promote_radius: 10,
                venue_id: business_location.id,
                contact_email: 'test@test.com',
                location_id: FactoryGirl.create(:location).slug,
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

            before do
              request_body.merge!(content: valid_event_params)
            end

            it 'return 201 status' do
              subject
              expect(response.status).to eql 201
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(Content.last).deep_merge(
                  content: {
                    promote_radius: valid_event_params[:promote_radius],
                    contact_email: valid_event_params[:contact_email],
                    cost: valid_event_params[:cost],
                    cost_type: valid_event_params[:cost_type],
                    title: valid_event_params[:title],
                    content: valid_event_params[:content]
                  }
                )
              )

              # The following is because response_json doesn't work well with nested
              # arrays.
              expect(response_json[:content][:schedules]).to match([
                {
                  subtitle: nil,
                  presenter_name: nil,
                  starts_at: valid_event_params[:schedules].first[:starts_at],
                  id: kind_of(Fixnum),
                  end_date: valid_event_params[:schedules].first[:starts_at],
                  repeats: 'once',
                  days_of_week: nil,
                  weeks_of_month: nil
                }
              ])

              expect(response_json[:content][:event_instances]).to match([
                {
                  id: kind_of(Fixnum),
                  subtitle: nil,
                  presenter_name: nil,
                  starts_at: valid_event_params[:schedules].first[:starts_at],
                  ends_at: nil,
                }
              ])
            end
          end
        end
      end
    end

    describe 'PUT /api/v3/contents/:id' do
      let(:content) { FactoryGirl.create :content }

      subject {
        put "/api/v3/contents/#{content.id}", request_body, headers
      }

      context 'without authentication' do
        it 'returns 401' do
          subject
          expect(response.status).to eql 401
        end
      end

      context 'with authentication, not allowed to edit' do
        let(:user) { FactoryGirl.create(:user) }

        before do
          headers.merge! auth_headers_for(user)
        end

        it 'returns 403 forbidden' do
          subject
          expect(response.status).to eql 403
        end

      end

      context 'with authentication, owner' do
        let(:user) { FactoryGirl.create(:user) }

        before do
          headers.merge! auth_headers_for(user)
        end

        describe 'news content' do
          let(:content) { FactoryGirl.create(:content, :news, created_by: user) }

          context 'valid params' do
            let(:valid_news_params) {
              {
                title: "A distinguished article, revised",
                biz_feed_public: false,
                content: "<p>Once upon a time...</p>",
                author_name: "Fred"
              }
            }

            before do
              request_body.merge!(content: valid_news_params)
            end

            it 'returns 200 status code' do
              subject
              expect(response.status).to eql 200
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(content).deep_merge(
                  content: {
                    author_name: valid_news_params[:author_name],
                    biz_feed_public: false,
                    title: valid_news_params[:title],
                    # @TODO: make sanitization more sane, it's wrapping
                    # and additional <p> here.
                    #content: valid_news_params[:content],
                    content: "<p>#{valid_news_params[:content]}</p>"
                  }
                )
              )
            end

            describe 'author_name' do
              context 'when the user is not the original author' do
                let(:other_user) { FactoryGirl.create :user, name: Faker::Name.name }
                before { content.update_attribute :created_by, other_user}

                context 'when passed the current user\'s name (*not* the author)' do
                  before do
                    valid_news_params[:author_name] = user.name
                  end

                  it 'should set `authors_is_created_by` to false' do
                    subject
                    expect(content.reload.authors_is_created_by).to be false
                  end
                end
              end

              context 'with authors_is_created_by true at first' do
                before do
                  content.authors = nil
                  content.authors_is_created_by = true
                  content.save
                  valid_news_params[:author_name] = Faker::Name.name
                end

                it 'should set `authors_is_created_by` to false' do
                  expect{subject}.to change{content.reload.authors_is_created_by}.to false
                end
              end
            end

            describe 'scheduling a draft for publishing' do
              before do
                content.update! pubdate: nil
                valid_news_params[:published_at] = 2.months.from_now
              end

              it 'should update the content pubdate' do
                expect{subject}.to change{content.reload.pubdate}
              end
            end

            describe 'unscheduling a previously scheduled draft' do
              before do
                content.update_attribute :pubdate, 2.months.from_now
                valid_news_params[:published_at] = nil
              end

              it 'should unset the pubdate and make the content a draft' do
                expect{subject}.to change{content.reload.pubdate}.to nil
              end
            end

            describe 'unpublishing published content' do
              before do
                content.update_attribute :pubdate, 1.week.ago
                valid_news_params[:published_at] = nil
              end

              it 'should not succeed' do
                expect{subject}.to_not change{content.reload.pubdate}
              end
            end

            describe 'modifying published content' do
              before do
                content.update_attribute :pubdate, 1.week.ago

                valid_news_params.merge!(
                  published_at: content.pubdate,
                  title: 'New Title For This Content'
                )
              end

              it 'should update the content' do
                expect{subject}.to change{content.reload.title}
              end
            end

            context 'without an organization specified' do
              before { content.update_attribute :organization_id, nil }

              context 'with pubdate' do
                before do
                  valid_news_params.merge!(
                    title: 'blerb',
                    content: Faker::Lorem.paragraph,
                    organization_id: nil,
                    published_at: Time.current
                  )
                end

                it 'should not update content' do
                  expect{subject}.to_not change{content.reload.title}
                end

                it 'should respond with errors' do
                  subject
                  expect(response_json[:errors]).to be_present
                end
              end

              context 'without pubdate' do
                before do
                  content.update! pubdate: nil
                  valid_news_params.merge!(
                    title: 'blerb',
                    content: Faker::Lorem.paragraph,
                    organization_id: nil,
                    published_at: nil
                  )
                end

                it 'should update the content' do
                  expect{subject}.to change{content.reload.title}.to valid_news_params[:title]
                end
              end
            end
          end
        end

        describe 'market content' do
          let(:content) { FactoryGirl.create(:content, :market_post, created_by: user) }

          context 'valid params' do
            let(:valid_market_params) {
              {
                biz_feed_public: false,
                title: "Casting Crowns",
                content: "<p>Come to the Well</p>",
                cost: "$10",
                promote_radius: 10,
                contact_email: 'john@galilee.com',
                location_id: FactoryGirl.create(:location).slug
              }
            }

            before do
              request_body.merge!(content: valid_market_params)
            end

            it 'return 200 status' do
              subject
              expect(response.status).to eql 200
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(content).deep_merge(
                  content: {
                    biz_feed_public: false,
                    # @TODO: make sanitization more sane, it's wrapping
                    # and additional <p> here.
                    #content: valid_market_params[:content],
                    content: "<p>#{valid_market_params[:content]}</p>",
                    contact_email: valid_market_params[:contact_email],
                    cost: '$10',
                    promote_radius: valid_market_params[:promote_radius],
                    title: valid_market_params[:title],
                    location_id: valid_market_params[:location_id]
                  }
                )
              )
            end
          end
        end

        describe 'talk content' do
          let(:content) { FactoryGirl.create(:content, :talk, created_by: user) }

          context 'valid params' do
            let(:valid_talk_params) {
              {
                title: "TFK",
                content: "<p>Oxygen: Inhale</p>",
                biz_feed_public: false,
              }
            }

            before do
              request_body.merge!(content: valid_talk_params)
            end

            it 'return 200 status' do
              subject
              expect(response.status).to eql 200
            end

            it 'returns json respresenation' do
              subject
              expect(response.body).to include_json(
                content_response_schema(Content.last).deep_merge(
                  content: {
                    biz_feed_public: false,
                    title: valid_talk_params[:title],
                    # @TODO: make sanitization more sane, it's wrapping
                    # and additional <p> here.
                    #content: valid_event_params[:content],
                    content: "<p>#{valid_talk_params[:content]}</p>",
                  }
                )
              )
            end
          end
        end


        describe 'event content' do
          let(:content) { FactoryGirl.create(:content, :event, created_by: user) }
          context 'valid params' do
            let(:valid_event_params) {
              {
                biz_feed_public: false,
                title: "Concert",
                content: "<p>Tickets for sale a the doors</p>",
                cost: "$10",
                cost_type: 'paid',
                promote_radius: 10,
                contact_email: 'test@test.com',
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

            before do
              request_body.merge!(content: valid_event_params)
            end

            it 'return 200 status' do
              subject
              expect(response.status).to eql 200
            end

            it 'returns json respresenation' do
              # Freezing time here because in reality the updated_at time
              # is changed as other related records are created
              Timecop.freeze do
                subject
                response_data = content_response_schema(content.reload).deep_merge(
                  content: {
                    biz_feed_public: false,
                    title: valid_event_params[:title],
                    promote_radius: valid_event_params[:promote_radius],
                    contact_email: valid_event_params[:contact_email],
                    cost: valid_event_params[:cost],
                    cost_type: valid_event_params[:cost_type],
                    # @TODO: make sanitization more sane, it's wrapping
                    # and additional <p> here.
                    #content: valid_event_params[:content],
                    content: "<p>#{valid_event_params[:content]}</p>",
                  }
                )

                expect(response.body).to include_json(response_data)
                # The following is because response_json doesn't work well with nested
                # arrays.
                expect(response_json[:content][:schedules]).to match([
                  {
                    subtitle: nil,
                    presenter_name: nil,
                    starts_at: valid_event_params[:schedules].first[:starts_at],
                    id: kind_of(Fixnum),
                    end_date: valid_event_params[:schedules].first[:starts_at],
                    repeats: 'once',
                    days_of_week: nil,
                    weeks_of_month: nil
                  }
                ])
              end
            end
          end
        end
      end
    end
  end

  describe 'GET /api/v3/contents/sitemap_ids' do
    let!(:org) { FactoryGirl.create :organization }
    let!(:alt_org) { FactoryGirl.create :organization }
    let!(:location) { FactoryGirl.create(:location)}

    let!(:consumer_app) { FactoryGirl.create :consumer_app_dailyuv, organizations: [org] }

    let!(:event) {
      FactoryGirl.create :content, :event, :published, organization: org
    }
    let!(:talk) {
      FactoryGirl.create :content, :talk, :published, organization: org
    }
    let!(:market_post) {
      FactoryGirl.create :content, :market_post, :published, organization: org
    }
    let!(:news) {
      FactoryGirl.create :content, :news, :published, organization: org
    }
    let!(:comment) {
      FactoryGirl.create :comment
    }

    before do
      comment.content.update organization: org
    end

    let(:query_params) { {} }

    subject do
      get '/api/v3/contents/sitemap_ids', query_params
      response_json
    end

    it 'returns the ids of the contents as expected (not events or comments by default)' do
      expect(subject[:content_ids]).to include *[talk, market_post, news].map(&:id)
      expect(subject[:content_ids]).to_not include event.id
      expect(subject[:content_ids]).to_not include comment.content.id
    end

    it 'does not return content that does not have at least one content_location that is not base' do
      news.update locations: []
      news.update base_locations: [location]
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include listserv content' do
      market_post.update organization_id: Organization::LISTSERV_ORG_ID
      expect(subject[:content_ids]).to_not include market_post.id
    end

    it 'allows specifying type separated by comma' do
      query_params[:type] = 'news,market'
      expect(subject[:content_ids]).to include *[news.id, market_post.id]
      expect(subject[:content_ids]).to_not include talk.id
    end

    it 'does not include content if not published' do
      news.update published: false
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content if pubdate is null' do
      news.update pubdate: nil
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content if pubdate is in the future' do
      news.update pubdate: Time.zone.now.tomorrow
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content removed' do
      news.update removed: true
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include non-dailyuv content' do
      event.update organization_id: alt_org.id
      expect(subject[:content_ids]).to_not include event.id
    end
  end

  describe "#update_subscriber_notification" do
    before do
      @organization = FactoryGirl.create :organization,
        org_type: 'Business',
        name: Content::BUSINESS_WHITELIST_FOR_NOTIFICATIONS.first
      allow(NotifySubscribersJob).to receive(:perform_later).and_return true
    end

    context "when business Content is type: campaign" do
      subject do
        FactoryGirl.create :content, :campaign,
          organization_id: @organization.id,
          published: true
      end

      it "does not notify subscribers" do
        expect(NotifySubscribersJob).not_to receive(:perform_later)
        subject
      end
    end
  end
end
