# frozen_string_literal: true

require 'rails_helper'
require 'addressable'

# The below is necessary for environments that do not read application.yml (CI)
ENV['MAILCHIMP_API_HOST'] = 'test.com'
ENV['MAILCHIMP_API_KEY'] = 'test.key'

def mc_formatted_time(datetime)
  datetime.strftime('%Y-%m-%d %H:%M:%S') if datetime.present?
end

RSpec.describe MailchimpService do
  before do
    allow(Figaro.env).to receive(:mailchimp_api_host).and_return('test.com')
    allow(Figaro.env).to receive(:mailchimp_api_key).and_return('test.key')
  end

  subject { MailchimpService }
  let(:base_url) { Figaro.env.mailchimp_api_host.to_s + '/3.0' }
  let(:auth) { ['user', Figaro.env.mailchimp_api_key] }

  it { is_expected.to respond_to(:subscribe) }
  it { is_expected.to respond_to(:unsubscribe) }

  describe 'update_subscription' do
    let(:mc_digest) { { id: 8 } }
    let(:mc_community) { { id: 9 } }
    let(:listserv) do
      FactoryGirl.create :listserv,
                         mc_list_id: 'list123',
                         mc_group_name: 'digest 1'
    end
    before do
      allow(described_class).to receive(:find_or_create_community).and_return(mc_community)
      allow(described_class).to receive(:find_or_create_digest).and_return(mc_digest)
    end

    context 'given a subscription that is confirmed, not unsubscribed' do
      let(:subscription) do
        FactoryGirl.create(:subscription,
                           :confirmed,
                           unsubscribed_at: nil,
                           listserv: listserv,
                           name: 'Bobby Roberts')
      end

      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      subject do
        MailchimpService.update_subscription(subscription)
      end

      context 'when user record' do
        let(:user) { FactoryGirl.create :user }

        before do
          subscription.update user: user
          allow(described_class).to receive(:find_or_create_merge_field).and_return({})
        end

        let!(:apistub) do
          stub_request(:put,
                       "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                         basic_auth: auth,
                         headers: {
                           'Content-Type' => 'application/json',
                           'Accept' => 'application/json'
                         },
                         body: {
                           email_type: subscription.email_type,
                           status: 'subscribed',
                           ip_signup: subscription.confirm_ip,
                           timestamp_signup: mc_formatted_time(subscription.created_at),
                           ip_opt: subscription.confirm_ip,
                           timestamp_opt: mc_formatted_time(subscription.confirmed_at),
                           email_address: subscription.email,
                           status_if_new: 'subscribed',
                           location: {
                             latitude: subscription.user.location.latitude,
                             longitude: subscription.user.location.longitude
                           },
                           merge_fields: {
                             FNAME: subscription.subscriber_name.split(/\s+/).first,
                             LNAME: subscription.subscriber_name.split(/\s+/).last,
                             ZIP: user.location.zip,
                             CITY: user.location.city,
                             STATE: user.location.state
                           },
                           interests: {
                             mc_digest[:id] => true
                           }
                         }.to_json
                       )
        end

        it 'does upsert on mailchimp api, with expected updates' do
          subject

          expect(apistub).to have_been_requested
        end

        it 'creates the ZIP, CITY, and STATE merge fields if they dont exist' do
          expect(described_class).to receive(:find_or_create_merge_field).with(
            listserv.mc_list_id,
            'ZIP',
            name: 'Zip',
            type: 'zip'
          )

          expect(described_class).to receive(:find_or_create_merge_field).with(
            listserv.mc_list_id,
            'CITY',
            name: 'City',
            type: 'text'
          )

          expect(described_class).to receive(:find_or_create_merge_field).with(
            listserv.mc_list_id,
            'STATE',
            name: 'State',
            type: 'text'
          )

          subject
        end

        context 'when user account location has no lat/lng' do
          before do
            user.location.update!(latitude: nil, longitude: nil)
          end

          it 'does upsert on mailchimp api, without location key' do
            api_without_location = stub_request(
              :put, "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}"
            ).with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              },
              body: {
                email_type: subscription.email_type,
                status: 'subscribed',
                ip_signup: subscription.confirm_ip,
                timestamp_signup: mc_formatted_time(subscription.created_at),
                ip_opt: subscription.confirm_ip,
                timestamp_opt: mc_formatted_time(subscription.confirmed_at),
                email_address: subscription.email,
                status_if_new: 'subscribed',
                merge_fields: {
                  FNAME: subscription.subscriber_name.split(/\s+/).first,
                  LNAME: subscription.subscriber_name.split(/\s+/).last,
                  ZIP: user.location.zip,
                  CITY: user.location.city,
                  STATE: user.location.state
                },
                interests: {
                  mc_digest[:id] => true
                }
              }.to_json
            )
            subject

            expect(api_without_location).to have_been_requested
          end
        end
      end

      context 'when no user record' do
        before do
          subscription.update user: nil
        end

        it 'does upsert on mailchimp api, with expected updates' do
          apistub = stub_request(:put,
                                 "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                                   basic_auth: auth,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'Accept' => 'application/json'
                                   },
                                   body: {
                                     email_type: subscription.email_type,
                                     status: 'subscribed',
                                     ip_signup: subscription.confirm_ip,
                                     timestamp_signup: mc_formatted_time(subscription.created_at),
                                     ip_opt: subscription.confirm_ip,
                                     timestamp_opt: mc_formatted_time(subscription.confirmed_at),
                                     email_address: subscription.email,
                                     status_if_new: 'subscribed',
                                     merge_fields: {
                                       FNAME: subscription.subscriber_name.split(/\s+/).first,
                                       LNAME: subscription.subscriber_name.split(/\s+/).last
                                     },
                                     interests: {
                                       mc_digest[:id] => true
                                     }

                                   }.to_json
                                 )

          subject

          expect(apistub).to have_been_requested
        end
      end

      context 'if response code >= 400' do
        before do
          allow(described_class).to receive(:find_or_create_merge_field)
        end
        let!(:apistub) do
          stub_request(:put,
                       "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").to_return(status: 400)
        end
        it 'raises exception' do
          expect { subject }.to raise_exception(MailchimpService::UnexpectedResponse)
        end
      end

      context 'when listserv does not have a mc_list_id' do
        before do
          listserv.update! mc_list_id: nil, mc_group_name: nil
        end

        it 'raises exception' do
          expect { subject }.to raise_exception(MailchimpService::MissingListId)
        end
      end
    end

    context 'given a subscription that confirmed, and unsubscribed' do
      let(:subscription) do
        FactoryGirl.create(:subscription,
                           :confirmed,
                           :unsubscribed,
                           listserv: listserv)
      end

      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      subject do
        MailchimpService.update_subscription(subscription)
      end

      context 'when user record' do
        let(:user) { FactoryGirl.create :user }

        before do
          subscription.update user: user
          allow(described_class).to receive(:find_or_create_merge_field).and_return({})
        end

        it 'does upsert on mailchimp api, with expected updates' do
          apistub = stub_request(:put,
                                 "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                                   basic_auth: auth,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'Accept' => 'application/json'
                                   },
                                   body: {
                                     email_type: subscription.email_type,
                                     status: 'subscribed',
                                     ip_signup: subscription.confirm_ip,
                                     timestamp_signup: mc_formatted_time(subscription.created_at),
                                     ip_opt: subscription.confirm_ip,
                                     timestamp_opt: mc_formatted_time(subscription.confirmed_at),
                                     email_address: subscription.email,
                                     status_if_new: 'subscribed',
                                     location: {
                                       latitude: subscription.user.location.latitude,
                                       longitude: subscription.user.location.longitude
                                     },
                                     merge_fields: {
                                       FNAME: subscription.subscriber_name.split(/\s+/).first,
                                       LNAME: subscription.subscriber_name.split(/\s+/).last,
                                       ZIP: user.location.zip,
                                       CITY: user.location.city,
                                       STATE: user.location.state
                                     },
                                     interests: {
                                       mc_digest[:id] => false
                                     }

                                   }.to_json
                                 )

          subject

          expect(apistub).to have_been_requested
        end
      end

      context 'when no user record' do
        before do
          subscription.update user: nil
        end

        it 'does upsert on mailchimp api, with expected updates' do
          apistub = stub_request(:put,
                                 "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                                   basic_auth: auth,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'Accept' => 'application/json'
                                   },
                                   body: {
                                     email_type: subscription.email_type,
                                     status: 'subscribed',
                                     ip_signup: subscription.confirm_ip,
                                     timestamp_signup: mc_formatted_time(subscription.created_at),
                                     ip_opt: subscription.confirm_ip,
                                     timestamp_opt: mc_formatted_time(subscription.confirmed_at),
                                     email_address: subscription.email,
                                     status_if_new: 'subscribed',
                                     merge_fields: {
                                       FNAME: subscription.subscriber_name.split(/\s+/).first,
                                       LNAME: subscription.subscriber_name.split(/\s+/).last
                                     },
                                     interests: {
                                       mc_digest[:id] => false
                                     }

                                   }.to_json
                                 )

          subject

          expect(apistub).to have_been_requested
        end
      end
    end

    context 'given a subscription that is not confirmed yet' do
      let(:subscription) do
        FactoryGirl.create(:subscription,
                           confirm_ip: nil,
                           confirmed_at: nil,
                           listserv: listserv)
      end

      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      subject do
        MailchimpService.update_subscription(subscription)
      end

      context 'when user record' do
        let(:user) { FactoryGirl.create :user }

        before do
          subscription.update user: user
          allow(described_class).to receive(:find_or_create_merge_field).and_return({})
        end

        it 'does upsert on mailchimp api, with expected updates' do
          apistub = stub_request(:put,
                                 "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                                   basic_auth: auth,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'Accept' => 'application/json'
                                   },
                                   body: {
                                     email_type: subscription.email_type,
                                     status: 'pending',
                                     timestamp_signup: mc_formatted_time(subscription.created_at),
                                     email_address: subscription.email,
                                     status_if_new: 'pending',
                                     location: {
                                       latitude: subscription.user.location.latitude,
                                       longitude: subscription.user.location.longitude
                                     },
                                     merge_fields: {
                                       FNAME: subscription.subscriber_name.split(/\s+/).first,
                                       LNAME: subscription.subscriber_name.split(/\s+/).last,
                                       ZIP: user.location.zip,
                                       CITY: user.location.city,
                                       STATE: user.location.state
                                     },
                                     interests: {
                                       mc_digest[:id] => true
                                     }

                                   }.to_json
                                 )

          subject

          expect(apistub).to have_been_requested
        end
      end

      context 'when no user record' do
        before do
          subscription.update user: nil
        end

        it 'does upsert on mailchimp api, with expected updates' do
          apistub = stub_request(:put,
                                 "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}").with(
                                   basic_auth: auth,
                                   headers: {
                                     'Content-Type' => 'application/json',
                                     'Accept' => 'application/json'
                                   },
                                   body: {
                                     email_type: subscription.email_type,
                                     status: 'pending',
                                     timestamp_signup: mc_formatted_time(subscription.created_at),
                                     email_address: subscription.email,
                                     status_if_new: 'pending',
                                     merge_fields: {
                                       FNAME: subscription.subscriber_name.split(/\s+/).first,
                                       LNAME: subscription.subscriber_name.split(/\s+/).last
                                     },
                                     interests: {
                                       mc_digest[:id] => true
                                     }

                                   }.to_json
                                 )

          subject

          expect(apistub).to have_been_requested
        end
      end
    end

    context 'given a subscription with mc_unsubscribed_at' do
      let(:subscription) do
        FactoryGirl.create(:subscription,
                           :confirmed,
                           unsubscribed_at: Time.zone.now,
                           mc_unsubscribed_at: Time.zone.now,
                           listserv: listserv,
                           name: 'Bobby Roberts')
      end

      subject do
        MailchimpService.update_subscription(subscription)
      end

      let(:subscriber_hash) { Digest::MD5.hexdigest subscription.email }

      it 'does not make api update' do
        apistub = stub_request(:put,
                               "https://#{base_url}/lists/#{listserv.mc_list_id}/members/#{subscriber_hash}")

        subject

        expect(apistub).to_not have_been_requested
      end
    end
  end

  describe '.subscribe' do
    context 'given a subscription' do
      let(:listserv) { FactoryGirl.create :listserv, mc_list_id: '99ss', mc_group_name: 'blah' }
      let(:subscription) do
        FactoryGirl.create(:subscription, :confirmed,
                           listserv: listserv,
                           name: 'Bobby Roberts')
      end
      subject do
        MailchimpService.subscribe(subscription)
      end

      it 'hands off to update_subscription' do
        expect(described_class).to receive(:update_subscription).with(subscription)
        subject
      end

      context 'when not confirmed' do
        before do
          subscription.update confirmed_at: nil
        end

        it 'raises exception' do
          expect { subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is not confirmed.")
        end
      end

      context 'when unsubscribed' do
        before do
          subscription.update unsubscribed_at: Time.current
        end

        it 'raises exception' do
          expect { subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is unsubscribed.")
        end
      end
    end
  end

  describe '.unsubscribe' do
    context 'given a subscription' do
      let(:listserv) { FactoryGirl.create :listserv, mc_list_id: '99ss', mc_group_name: 'fadsj' }
      let(:subscription) do
        FactoryGirl.create(:subscription,
                           :confirmed,
                           :unsubscribed,
                           listserv: listserv)
      end
      subject do
        MailchimpService.unsubscribe(subscription)
      end

      it 'passes off to #update_subscription' do
        expect(described_class).to receive(:update_subscription).with(subscription)
        subject
      end

      context 'when not unsubscribed' do
        before do
          subscription.update unsubscribed_at: nil
        end

        it 'raises exception' do
          expect { subject }.to raise_error(RuntimeError, "Subscription #{subscription.id} is not unsubscribed.")
        end
      end
    end
  end

  describe '.create_campaign' do
    context 'given a digest model, and text/html content' do
      let(:listserv) do
        FactoryGirl.create :listserv,
                           mc_list_id: 'M@ailCh1mp',
                           mc_group_name: 'Digest 1'
      end
      let(:location) { FactoryGirl.create :location }
      let!(:digest) do
        FactoryGirl.create :listserv_digest,
                           listserv: listserv,
                           title: 'Digest of the day (q1)',
                           subject: 'Digest of the day',
                           from_name: 'HereCast',
                           reply_to: 'duv@duv.net',
                           location_ids: [location.id]
      end
      let(:content) { '<p>Hello World!</p>' }

      let(:segment) do
        { id: 123_987, name: "#{listserv.name}-#{digest.id}" }
      end

      subject { MailchimpService.create_campaign(digest, content) }

      before do
        allow(described_class).to receive(:create_segment).with(digest).and_return(segment)
      end

      let!(:apistub_create) do
        stub_request(:post,
                     "https://#{base_url}/campaigns").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       },
                       body: hash_including(
                         type: 'regular',
                         recipients: {
                           list_id: listserv.mc_list_id,
                           segment_opts: {
                             saved_segment_id: segment[:id]
                           }
                         },
                         settings: {
                           title: digest.title,
                           subject_line: digest.subject,
                           from_name: digest.from_name,
                           reply_to: digest.reply_to
                         },
                         tracking: {
                           google_analytics: digest.ga_tag
                         }
                       )
                     ).to_return(
                       status: 201,
                       headers: {
                         'Content-Type' => 'application/json'
                       },
                       body: {
                         id: '123abc'
                       }.to_json
                     )
      end

      let!(:apistub_content) do
        stub_request(:put,
                     "https://#{base_url}/campaigns/123abc/content").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       },
                       body: hash_including(
                         html: content
                       )
                     )
      end

      it 'creates mailchimp campaign with expected attributes' do
        subject
        expect(apistub_create).to have_been_requested
        expect(apistub_content).to have_been_requested
      end

      it 'returns campaign info, including id' do
        expect(subject).to match hash_including(
          id: a_kind_of(String)
        )
      end

      it 'assigns segement id back to digest model' do
        expect { subject }.to change {
          digest.mc_segment_id
        }.to(segment[:id].to_s)
      end
    end
  end

  describe '.send_campaign' do
    context 'given a campaign id' do
      let(:campaign_id) { '98fds90' }

      subject { MailchimpService.send_campaign(campaign_id) }

      let!(:apistub) do
        stub_request(:post,
                     "https://#{base_url}/campaigns/#{campaign_id}/actions/send").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       }
                     )
      end

      it 'triggers campaign send on mailchimp api' do
        subject
        expect(apistub).to have_been_requested
      end

      context 'if response code >= 400' do
        it 'raises exception' do
          apistub.to_return(status: 400)

          expect { subject }.to raise_exception(MailchimpService::UnexpectedResponse)
        end
      end
    end
  end

  describe '.interest_categories' do
    context 'given a list id' do
      let(:list_id) { 'ioiu23' }

      subject { described_class.interest_categories(list_id) }

      let!(:apistub) do
        stub_request(:get,
                     "https://#{base_url}/lists/#{list_id}/interest-categories").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       }
                     ).to_return(
                       status: 200,
                       headers: {
                         'Content-Type' => 'application/json'
                       },
                       body: {
                         list_id: list_id,
                         categories: [
                           {
                             id: 1,
                             list_id: list_id,
                             title: 'Category1',
                             display_order: 0,
                             type: 'checkboxes',
                             links: []
                           }
                         ],
                         total_items: 1,
                         links: []
                       }.to_json
                     )
      end

      it 'returns array with symbolized hash representation of categories' do
        expect(subject).to match([
                                   {
                                     id: 1,
                                     title: 'Category1',
                                     type: 'checkboxes',
                                     list_id: list_id,
                                     display_order: 0
                                   }
                                 ])
      end
    end
  end

  describe '.interests' do
    context 'given list id, and interest category id' do
      let(:list_id) { 'abc123' }
      let(:interest_category_id) { 123 }

      subject { described_class.interests(list_id, interest_category_id) }

      let!(:apistub) do
        stub_request(:get,
                     "https://#{base_url}/lists/#{list_id}/interest-categories/#{interest_category_id}/interests").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       }
                     ).to_return(
                       status: 200,
                       headers: {
                         'Content-Type' => 'application/json'
                       },
                       body: {
                         interests: [
                           {
                             id: 1,
                             category_id: interest_category_id,
                             list_id: list_id,
                             name: 'Interest 1',
                             display_order: 0,
                             links: []
                           }
                         ],
                         total_items: 1,
                         links: []
                       }.to_json
                     )
      end

      it 'returns an array with symbolized hash version of interests' do
        expect(subject).to match([
                                   {
                                     id: 1,
                                     category_id: interest_category_id,
                                     list_id: list_id,
                                     name: 'Interest 1',
                                     display_order: 0
                                   }
                                 ])
      end
    end
  end

  describe '.merge_fields' do
    context 'given a list id' do
      let(:list_id) { 'ioiu23' }

      subject { described_class.merge_fields(list_id) }

      let!(:apistub) do
        stub_request(:get,
                     "https://#{base_url}/lists/#{list_id}/merge-fields").with(
                       basic_auth: auth,
                       headers: {
                         'Content-Type' => 'application/json',
                         'Accept' => 'application/json'
                       }
                     ).to_return(
                       status: 200,
                       headers: {
                         'Content-Type' => 'application/json'
                       },
                       body: {
                         merge_fields: [
                           {
                             merge_id: 1,
                             tag: 'FNAME',
                             name: 'First Name',
                             display_order: 0,
                             type: 'text',
                             required: false,
                             public: true,
                             default_value: '',
                             links: []
                           }
                         ],
                         total_items: 1,
                         links: []
                       }.to_json
                     )
      end

      it 'returns array with symbolized hash representation of categories' do
        expect(subject).to match([
                                   {
                                     merge_id: 1,
                                     name: 'First Name',
                                     type: 'text',
                                     tag: 'FNAME',
                                     display_order: 0,
                                     required: false,
                                     public: true,
                                     default_value: ''
                                   }
                                 ])
      end
    end
  end

  describe 'find_or_create_category' do
    context 'Given a list_id and interest category name;' do
      let(:list_id) { 'abc321' }
      let(:name) { 'digests' }

      subject { described_class.find_or_create_category(list_id, name) }

      context 'When interest category exists in mailchimp;' do
        let(:named_category) do
          {
            id: 909,
            list_id: list_id,
            title: name,
            display_order: 0,
            type: 'checkboxes'
          }
        end
        before do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/interest-categories")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                list_id: list_id,
                categories: [
                  named_category,
                  {
                    id: 910,
                    list_id: list_id,
                    title: 'Other Category',
                    display_order: 0,
                    type: 'checkboxes',
                    links: []
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        it 'returns a symbolized hash with interest category fields' do
          expect(subject).to match a_hash_including(named_category)
        end
      end

      context 'When interest category does not yet exist' do
        let(:named_category) do
          {
            id: 909,
            list_id: list_id,
            title: name,
            display_order: 0,
            type: 'checkboxes'
          }
        end
        before do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/interest-categories")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                list_id: list_id,
                categories: [
                  {
                    id: 910,
                    list_id: list_id,
                    title: 'Other Category',
                    display_order: 0,
                    type: 'checkboxes',
                    links: []
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        it 'it creates one, and returns a symbolized hash with interest category fields' do
          create_request = stub_request(:post, "https://#{base_url}/lists/#{list_id}/interest-categories")\
                           .with(
                             basic_auth: auth,
                             headers: {
                               'Content-Type' => 'application/json',
                               'Accept' => 'application/json'
                             },
                             body: hash_including(
                               type: 'checkboxes',
                               title: name
                             )
                           )\
                           .to_return(
                             status: 200,
                             headers: {
                               'Content-Type' => 'application/json'
                             },
                             body: named_category.to_json
                           )
          expect(subject).to match a_hash_including(named_category)
        end

        context 'options' do
          let(:options) { { type: 'dropdown', display_order: 1 } }
          let(:named_category) do
            {
              id: 909,
              list_id: list_id,
              title: name,
              display_order: options[:display_order],
              type: options[:type]
            }
          end

          it 'allows customizing display_order, and type' do
            create_request = stub_request(:post, "https://#{base_url}/lists/#{list_id}/interest-categories")\
                             .with(
                               basic_auth: auth,
                               headers: {
                                 'Content-Type' => 'application/json',
                                 'Accept' => 'application/json'
                               },
                               body: hash_including(
                                 title: name,
                                 type: options[:type],
                                 display_order: options[:display_order]
                               )
                             )\
                             .to_return(
                               status: 200,
                               headers: {
                                 'Content-Type' => 'application/json'
                               },
                               body: named_category.to_json
                             )

            described_class.find_or_create_category(list_id, name, options)

            expect(create_request).to have_been_requested
          end
        end
      end
    end
  end

  describe '.find_or_create_digest' do
    context 'Given a list id, and name' do
      let(:list_id) { 'abc321' }
      let(:name) { 'Upper Valley Digest' }
      let(:digest_category) do
        {
          id: '909',
          list_id: list_id,
          title: 'digests',
          display_order: 0,
          type: 'checkboxes'
        }
      end
      let(:named_interest) do
        {
          id: '1909',
          list_id: list_id,
          category_id: digest_category[:id],
          name: name,
          display_order: 0
        }
      end

      subject { described_class.find_or_create_digest(list_id, name) }

      it 'sets up digests category automatically' do
        stub_request(:get, "https://#{base_url}/lists/#{list_id}/interest-categories/#{digest_category[:id]}/interests")\
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            },
            body: {
              interests: [named_interest]
            }.to_json
          )
        expect(described_class).to receive(:find_or_create_category)\
          .with(list_id, 'digests', type: 'checkboxes').and_return(digest_category)
        subject
      end

      before do
        allow(described_class).to receive(:find_or_create_category)\
          .with(list_id, 'digests', type: 'checkboxes').and_return(digest_category)
      end

      context 'When interest exists in mailchimp;' do
        before do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/interest-categories/#{digest_category[:id]}/interests")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                interests: [
                  named_interest,
                  {
                    id: '910',
                    list_id: list_id,
                    category_id: digest_category[:id],
                    name: 'Other Digest',
                    display_order: 0
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        it 'returns a symbolized hash representation of correct digest' do
          expect(subject).to match a_hash_including(named_interest)
        end
      end

      context 'When digest does not exist in mailchimp' do
        before do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/interest-categories/#{digest_category[:id]}/interests")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                interests: [
                  {
                    id: '910',
                    list_id: list_id,
                    category_id: digest_category[:id],
                    name: 'Other Category',
                    display_order: 0
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        let!(:create_request) do
          stub_request(:post, "https://#{base_url}/lists/#{list_id}/interest-categories/#{digest_category[:id]}/interests")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              },
              body: hash_including(
                name: name
              )
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: named_interest.to_json
            )
        end

        it 'it creates one, and returns a symbolized hash with interest fields' do
          expect(subject).to match a_hash_including(named_interest)
          expect(create_request).to have_been_requested
        end
      end
    end
  end

  describe '.find_or_create_merge_field' do
    context 'Given a list id, merge field name, and options' do
      let(:list_id) { 'mc123' }
      let(:tag) { 'CITY' }
      let(:options) do
        {
          name: 'City',
          type: 'text',
          display_order: 0,
          public: true,
          default_value: ''
        }
      end

      subject { described_class.find_or_create_merge_field(list_id, tag, options) }

      context 'merge field exists already' do
        let!(:index_stub) do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/merge-fields")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                merge_fields: [
                  {
                    merge_id: 910,
                    tag: tag,
                    list_id: list_id,
                    name: options[:name],
                    display_order: options[:display_order],
                    type: options[:type],
                    public: options[:public],
                    default_value: options[:default_value]
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        it 'returns a symbolized hash of the merge field as represented in mailchimp' do
          expect(subject).to match(a_hash_including(
                                     merge_id: an_instance_of(Integer),
                                     tag: tag,
                                     name: options[:name],
                                     type: options[:type],
                                     public: true
                                   ))
        end
      end

      context 'when merge field does not yet exist' do
        let!(:index_stub) do
          stub_request(:get, "https://#{base_url}/lists/#{list_id}/merge-fields")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              }
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                merge_fields: [
                  {
                    merge_id: 910,
                    tag: 'OTHER',
                    list_id: list_id,
                    name: 'Other'
                  }
                ],
                total_items: 1,
                links: []
              }.to_json
            )
        end

        let!(:create_stub) do
          stub_request(:post, "https://#{base_url}/lists/#{list_id}/merge-fields")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              },
              body: hash_including(
                tag: tag,
                name: options[:name],
                type: options[:type]
              )
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: {
                merge_id: 911,
                tag: tag,
                list_id: list_id,
                name: options[:name],
                display_order: options[:display_order],
                type: options[:type],
                public: options[:public],
                default_value: options[:default_value]
              }.to_json
            )
        end

        it 'creates merge tag' do
          subject
          expect(create_stub).to have_been_requested
        end

        it 'returns a symbolized hash of the merge field as represented in mailchimp' do
          expect(subject).to match(a_hash_including(
                                     merge_id: an_instance_of(Integer),
                                     tag: tag,
                                     name: options[:name],
                                     type: options[:type],
                                     public: true
                                   ))
        end
      end
    end
  end

  describe '.rename_digest' do
    context 'Given a list id, old name, and new name;' do
      let(:list_id) { 'mc123' }
      let(:old_name) { 'Digest foo' }
      let(:new_name) { 'Digest bar' }
      let(:digest_group) { { id: 'interest-group-1', title: 'Digests' } }
      let(:digest) { { id: 'interest-9', name: old_name } }

      subject { described_class.rename_digest(list_id, old_name, new_name) }

      before do
        allow(described_class).to receive(:find_or_create_category).with(
          list_id, 'digests'
        ).and_return(digest_group)

        allow(described_class).to receive(:find_or_create_digest).with(
          list_id,
          old_name
        ).and_return(digest)
      end

      it 'renames interest in mailchimp' do
        api_request = stub_request(:patch,
                                   "https://#{base_url}/lists/#{list_id}/interest-categories/#{digest_group[:id]}/interests/#{digest[:id]}")\
                      .with(
                        basic_auth: auth,
                        headers: {
                          'Content-Type' => 'application/json',
                          'Accept' => 'application/json'
                        },
                        body: hash_including(
                          name: new_name
                        )
                      )\
                      .to_return(
                        status: 200,
                        headers: {
                          'Content-Type' => 'application/json'
                        },
                        body: { id: digest[:id], name: new_name }.to_json
                      )
        subject
        expect(api_request).to have_been_requested
      end

      context 'when old name is blank' do
        let(:old_name) { nil }

        it 'does not try to create with an empty digest name' do
          allow(described_class).to receive(:find_or_create_digest).with(
            list_id,
            new_name
          )
          expect(described_class).to_not receive(:find_or_create_digest).with(
            list_id,
            nil
          )

          subject
        end

        it 'calls find_or_create_digest with new name' do
          expect(described_class).to receive(:find_or_create_digest).with(
            list_id,
            new_name
          )
          subject
        end
      end

      context 'when new name is blank' do
        let(:new_name) { nil }

        it 'does not rename' do
          expect(described_class).to_not receive(:find_or_create_digest).with(
            list_id,
            nil
          )

          subject
        end
      end
    end
  end

  describe '.create_segment' do
    context 'given a listserv digest instance' do
      let(:list_id) { '1234' }
      let(:listserv) do
        FactoryGirl.create :listserv,
                           mc_list_id: list_id,
                           mc_group_name: 'Test Digest'
      end
      let!(:digest) do
        FactoryGirl.create :listserv_digest,
                           listserv: listserv
      end

      subject { described_class.create_segment(digest) }

      context 'when digest has subscriber_emails' do
        let(:emails) do
          [
            'test@company.com',
            'test2@company.com'
          ]
        end

        before do
          allow(digest).to receive(:subscriber_emails).and_return(emails)
        end

        let(:created_segment) do
          {
            id: 123_456,
            name: "#{listserv.name}-#{digest.id}",
            member_count: 1,
            type: 'saved',
            list_id: list_id
          }
        end

        let!(:create_request) do
          stub_request(:post, "https://#{base_url}/lists/#{list_id}/segments")\
            .with(
              basic_auth: auth,
              headers: {
                'Content-Type' => 'application/json',
                'Accept' => 'application/json'
              },
              body: {
                name: created_segment[:name],
                static_segment: emails
              }.to_json
            )\
            .to_return(
              status: 200,
              headers: {
                'Content-Type' => 'application/json'
              },
              body: created_segment.to_json
            )
        end

        it 'creates a digest, and returns the symbolized hash representation' do
          expect(subject).to match hash_including(created_segment)
        end
      end

      context 'when digest does not have subscriber_emails' do
        before do
          allow(digest).to receive(:subscriber_emails).and_return([])
        end

        it 'raises NoSubscribersPresent' do
          expect { subject }.to raise_error(MailchimpService::NoSubscribersPresent)
        end
      end
    end
  end

  describe 'add_unsubscribe_hook' do
    let(:list_id) { '1234' }
    let(:listserv) do
      FactoryGirl.create :listserv,
                         mc_list_id: list_id,
                         mc_group_name: 'Test Digest'
    end

    before do
      allow(Figaro.env).to receive('default_consumer_host').and_return('http://test.com')
    end

    subject { described_class.add_unsubscribe_hook(list_id) }

    it 'adds a new webhook for the list' do
      webhook_request = stub_request(:get, "https://#{base_url}/lists/#{list_id}/webhooks")\
                        .with(
                          basic_auth: auth,
                          headers: {
                            'Content-Type' => 'application/json',
                            'Accept' => 'application/json'
                          }
                        ).to_return(
                          status: 200,
                          headers: {
                            'Content-Type' => 'application/json'
                          },
                          body: { webhooks: [] }.to_json
                        )
      api_request = stub_request(:post,
                                 "https://#{base_url}/lists/#{list_id}/webhooks")\
                    .with(
                      basic_auth: auth,
                      headers: {
                        'Content-Type' => 'application/json',
                        'Accept' => 'application/json'
                      },
                      body: {
                        url: "#{Figaro.env.default_consumer_host}/api/v3/subscriptions/unsubscribe_from_mailchimp",
                        events: {
                          subscribe: false,
                          unsubscribe: true,
                          profile: false,
                          cleaned: false,
                          upemail: false,
                          campaign: false
                        },
                        sources: {
                          user: true,
                          admin: true,
                          api: true
                        }
                      }.to_json
                    )\
                    .to_return(
                      status: 200,
                      headers: {
                        'Content-Type' => 'application/json'
                      }
                    )
      subject
      expect(webhook_request).to have_been_requested
      expect(api_request).to have_been_requested
    end
  end
end
