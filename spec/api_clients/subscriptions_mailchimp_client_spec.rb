require 'spec_helper'

# The below is necessary for environments that do not read application.yml (CI)
ENV['SUBSCRIPTIONS_MAILCHIMP_API_HOST'] = "test.com"
ENV['SUBSCRIPTIONS_MAILCHIMP_API_KEY']  = "test.key"

RSpec.describe SubscriptionsMailchimpClient do
  subject { SubscriptionsMailchimpClient }
  let(:endpoint) { "https://#{Figaro.env.subscriptions_mailchimp_api_host}/3.0" }
  let(:auth)     { ["user", Figaro.env.subscriptions_mailchimp_api_key] }

  describe "#lists" do
    let(:pagination_params1)  { {offset:   0, count: 100}.to_param }
    let(:pagination_params2)  { {offset: 100, count: 100}.to_param }
    let(:pagination_params3)  { {offset: 200, count: 100}.to_param }

    let!(:apistub1) {
      stub_request(:get, "#{endpoint}/lists?#{pagination_params1}").with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        }
      ).to_return(body: {lists: ['list1', 'list2']}.to_json)
    }

    let!(:apistub2) {
      stub_request(:get, "#{endpoint}/lists?#{pagination_params2}").with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        }
      ).to_return(body: {lists: ['list3']}.to_json)
    }

    let!(:apistub3) {
      stub_request(:get, "#{endpoint}/lists?#{pagination_params3}").with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        }
      ).to_return(body: {lists: []}.to_json)
    }

    it "returns all the lists, regardless of pagination" do
      expect(subject.lists.to_a).to eq ['list1', 'list2', 'list3']
    end
  end

  describe "#create_campaign" do
    let!(:apistub) {
      stub_request(:post,
                   "#{endpoint}/campaigns"
      ).with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        },
        body:       {
                      type:       'regular',
                      recipients: {list_id: "314a"},
                      settings:   {
                        subject_line: "sub",
                        title:        "tle",
                        from_name:    "from",
                        reply_to:     "reply",
                      },
                    }.to_json
      ).to_return(body: {
                          id: 'abc'
                        }.to_json
      )
    }

    it "returns the list ID" do
      expect(subject.create_campaign(list_identifier: "314a",
                                     subject:         "sub",
                                     title:           "tle",
                                     from_name:       "from",
                                     reply_to:        "reply")).to eq 'abc'
    end
  end

  describe "#update_campaign" do
    let!(:apistub) {
      stub_request(:patch,
                   "#{endpoint}/campaigns/qwer"
      ).with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        },
        body:       {
                      settings:   {
                        subject_line: "sub",
                        title:        "tle",
                        from_name:    "from",
                        reply_to:     "reply",
                      },
                    }.to_json
      ).to_return(body: {
                          id: 'abc'
                        }.to_json
      )
    }

    it "executes without exception" do
      expect{subject.update_campaign(campaign_identifier: "qwer",
                                     subject:             "sub",
                                     title:               "tle",
                                     from_name:           "from",
                                     reply_to:            "reply")}.not_to raise_error
    end
  end

  describe "#create_content" do
    let!(:apistub) {
      stub_request(:put,
                   "#{endpoint}/campaigns/qwer/content"
      ).with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        },
        body:       {
                      html: "<p></p>",
                    }.to_json
      )
    }

    it "is successful" do
      expect(subject.set_content(campaign_identifier: 'qwer', html: "<p></p>")).to be_success
    end
  end

  describe "#get_status" do
    let!(:apistub) {
      stub_request(:get,
                   "#{endpoint}/campaigns/qwer"
      ).with(
        basic_auth: auth,
        headers:    {
          "Content-Type" => 'application/json',
          "Accept"       => 'application/json'
        }
      ).to_return(body: {status: 'this is a status'}.to_json)
    }

    it "is successful" do
      expect(subject.get_status(campaign_identifier: 'qwer')).to eq 'this is a status'
    end
  end
end
