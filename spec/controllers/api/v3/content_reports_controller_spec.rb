require 'spec_helper'

describe Api::V3::ContentReportsController, type: :controller do
  before do
    @content_report = FactoryGirl.create :content_report, report_date: Date.new(2016,1,1)
    @user = FactoryGirl.create :user
    @content = FactoryGirl.create :content, pubdate: Date.new(2016,1,1),
      created_by: @user
    @content_report.content = @content
    @content_report.save
  end

  subject { get :index, start_date: '2015-01-01', end_date: '2017-01-01' }

  it "returns appropriate information" do
    subject
    content_report = JSON.parse(response.body)['content_reports'][0]

    expect(content_report).to match({
      "Date" => @content_report.report_date.strftime("%Y-%m-%d %T"),
      "Author" => @user.name,
      "Publication Date" => @content_report.content.pubdate.strftime("%Y-%m-%d %T"),
      "Title" => @content_report.content.title,
      "Views" => @content_report.view_count.to_s,
      "Ad Clicks" => @content_report.banner_click_count.to_s,
      "Comments" => "0",
      "Paid for content?" => 'f',
      "Title + PubDate" => "#{@content_report.content.title} (#{@content_report.content.pubdate.strftime('%Y-%m-%d %H:%M:%S')})"
    })
  end
end
