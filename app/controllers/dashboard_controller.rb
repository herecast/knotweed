class DashboardController < ApplicationController

    @@mixpanel = Mixpanel::Client.new(
      api_key: Figaro.env.mixpanel_api_key,
      api_secret: Figaro.env.mixpanel_api_secret
    )

  # asynchronously load the mixpanel charts into the dashboard page
  # in case there's an error.
  def mixpanel_charts
    @metrics = {}
    data = @@mixpanel.request(
      'engage',
      where: 'properties["testGroup"]!="subtext"'
    )
    yesterday = (Time.current - 1.day).strftime("%Y-%m-%d")
    
    landing_clicks = @@mixpanel.request(
      'segmentation',
      event: "clickLandingLink",
      from_date: 1.week.ago.strftime("%Y-%m-%d"),
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["clickLandingLink"]
    relevant_clicks = @@mixpanel.request(
      'segmentation',
      event: "clickRelevantLink",
      from_date: 1.week.ago.strftime("%Y-%m-%d"),
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["clickRelevantLink"]

    @metrics[:relevant_clicks] = { yesterday: relevant_clicks[yesterday] }
    @metrics[:relevant_clicks][:past_week] = relevant_clicks.map{ |k,v| v }.inject(:+)
    @metrics[:landing_clicks] = { yesterday: landing_clicks[yesterday] }
    @metrics[:landing_clicks][:past_week] = landing_clicks.map{ |k,v| v }.inject(:+)
    @metrics[:article_clicks] = { yesterday: @metrics[:relevant_clicks][:yesterday] + @metrics[:landing_clicks][:yesterday] }
    @metrics[:article_clicks][:past_week] = @metrics[:relevant_clicks][:past_week] + @metrics[:landing_clicks][:past_week]

    clicks = [:yesterday, :past_week].map do |sym| 
      [{
        label: "Relevant Clicks: #{@metrics[:relevant_clicks][sym]}",
        data: ((@metrics[:relevant_clicks][sym] / @metrics[:article_clicks][sym].to_f) * 100)
      }, {
        label: "Landing Clicks: #{@metrics[:landing_clicks][sym]}",
        data: ((@metrics[:landing_clicks][sym] / @metrics[:article_clicks][sym].to_f) * 100)
      }].to_json
    end    
    @yesterday_pie_chart_data = clicks[0]
    @pastweek_pie_chart_data  = clicks[1]
    render partial: "mixpanel_charts"
  end

  def index
    authorize! :access, :dashboard
  end

  def article_clicks
    process_time_frame

    params[:article_clicks_time_frame] = params[:time_frame]

    landing_clicks = @@mixpanel.request(
      'segmentation',
      event: "clickLandingLink",
      from_date: @from_date,
      unit: @unit,
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["clickLandingLink"]
    relevant_clicks = @@mixpanel.request(
      'segmentation',
      event: "clickRelevantLink",
      from_date: @from_date,
      unit: @unit,
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["clickRelevantLink"]
    total_clicks = relevant_clicks.merge(landing_clicks){|k,v1,v2| v1 + v2 }
    ordered = total_clicks.map{ |k,v| [Chronic.parse(k).to_i*1000, v] }.sort{ |a,b| a[0]<=>b[0] }

    @article_clicks_json = [
      {
        label: "Total Clicks",
        data: ordered
      }
    ].to_json

   render partial: "dashboard/article_clicks"
    
  end

  def total_sign_ins
    process_time_frame

    params[:sign_in_time_frame] = params[:time_frame]
    # default value month
    sign_in_data = @@mixpanel.request(
      'segmentation',
      event: "signIn",
      from_date: @from_date,
      unit: @unit,
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["signIn"]
    ordered = sign_in_data.map{ |k,v| [Chronic.parse(k).to_i*1000, v] }.sort{ |a,b| a[0]<=>b[0] }

    unique_sign_in_data = @@mixpanel.request(
      'segmentation',
      event: "signIn",
      from_date: @from_date,
      unit: @unit,
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"',
      type: 'unique'
    )["data"]["values"]["signIn"]
    ordered_uniq = unique_sign_in_data.map{ |k,v| [Chronic.parse(k).to_i*1000, v] }.sort{ |a,b| a[0]<=>b[0] }

    @sign_in_json = [
      {
        label: "Total Sign Ins",
        data: ordered
      },
      {
        label: "Unique Sign Ins",
        data: ordered_uniq
      }
    ].to_json
    render partial: "dashboard/total_sign_ins"
  end

  private

  def process_time_frame
    if params[:time_frame].nil?
      @from_date = 1.month.ago.strftime("%Y-%m-%d")
      @unit = "day"
    elsif params[:time_frame] == "month"
      @from_date = 1.month.ago.strftime("%Y-%m-%d")
      @unit = "day"
    elsif params[:time_frame] == "week"
      @from_date = 1.week.ago.strftime("%Y-%m-%d")
      @unit = "day"
    elsif params[:time_frame] == "day"
      @from_date = 1.day.ago.strftime("%Y-%m-%d")
      @unit = "hour"
    else # try to parse a date out of time frame
      @from_date = Chronic.parse(params[:time_frame])
      @unit = "day"
    end
  end

end
