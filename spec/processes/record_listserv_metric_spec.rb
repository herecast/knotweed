require 'spec_helper'

RSpec.describe RecordListservMetric do

  describe "#create_metric" do
    context "without a ListservContent record" do
      subject { RecordListservMetric.call('create_metric', nil) }

      it "does not create ListservContentMetric record" do
        expect{ subject }.to raise_error(NoMethodError)
      end
    end

    context "with ListservContent record" do
      before do
        @listserv_content = FactoryGirl.create :listserv_content, sender_email: "darth@republic.co"
      end

      subject { RecordListservMetric.call('create_metric', @listserv_content) }

      it "creates ListservContentMetric record" do
        expect{ subject }.to change{
          ListservContentMetric.count
        }.by 1
      end

      it "updates ListservContentMetric with listserv_content information" do
        subject
        listserv_content_metric = ListservContentMetric.first
        expect(listserv_content_metric.listserv_content_id).to eq @listserv_content.id
        expect(listserv_content_metric.email).to               eq @listserv_content.sender_email
        expect(listserv_content_metric.time_sent).to           be_truthy
        expect(listserv_content_metric.step_reached).to        eq 'send_email'
      end
    end
  end

  describe "#update_metric" do
    before do
      @listserv_content = FactoryGirl.create :listserv_content
      @listserv_content.listserv_content_metric = FactoryGirl.create :listserv_content_metric
      @params = {
        enhance_link_clicked: true,
        channel_type: 'light_saber',
        step_reached: 'mustafar_station'
      }
    end

    subject { RecordListservMetric.call('update_metric', @listserv_content, @params) }

    context "when user clicks enhance link" do
      it "updates listserv_content_metric.enhance_link_clicked to true" do
        subject
        expect(@listserv_content.listserv_content_metric.reload.enhance_link_clicked).to be true
        expect(@listserv_content.listserv_content_metric.reload.post_type).to eq 'light_saber'
        expect(@listserv_content.listserv_content_metric.reload.step_reached).to eq 'mustafar_station'
      end
    end
  end

  describe "#complete_metric" do
    before do
      @listserv_content = FactoryGirl.create :listserv_content
      RecordListservMetric.call(:create_metric, @listserv_content)
      @attributes = { verify_ip: '192.168.0.1' }
    end

    subject { RecordListservMetric.call('complete_metric', @listserv_content, @attributes) }

    context "when post is not enhanced" do
      it "updates verified to true" do
        expect{ subject }.to change{
          ListservContentMetric.first.verified
        }.to true
      end
    end

    context "when listserv_content has content_id" do
      before do
        @listserv_content.content = FactoryGirl.create :content
        user = FactoryGirl.create :user, name: 'Obi Wan'
        @listserv_content.content.update_attribute(:created_by, user)
        @attributes.merge!(
          content_id: @listserv_content.content.id,
          channel_type: 'Event'
        )
      end

      it "marks ListservContentMetric record as enhanced updates" do
        subject
        listserv_content_metric = ListservContentMetric.first
        expect(listserv_content_metric.verified).to     be true
        expect(listserv_content_metric.enhanced).to     be true
        expect(listserv_content_metric.post_type).to    eq 'Event'
        expect(listserv_content_metric.username).to     eq "Obi Wan"
        expect(listserv_content_metric.step_reached).to eq 'publish_post'
      end
    end
  end
end
