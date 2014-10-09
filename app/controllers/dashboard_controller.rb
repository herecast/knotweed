class DashboardController < ApplicationController

  @@mixpanel = Mixpanel::Client.new(
    api_key: Figaro.env.mixpanel_api_key,
    api_secret: Figaro.env.mixpanel_api_secret
  )

  def index
    @metrics = {}
    data = @@mixpanel.request(
      'engage',
      where: 'properties["testGroup"]!="subtext"'
    )
    @metrics[:total_users] = data["results"].count
    sign_in_data = @@mixpanel.request(
      'segmentation',
      event: "signIn",
      from_date: 1.week.ago.strftime("%Y-%m-%d"),
      to_date: Time.zone.now.strftime("%Y-%m-%d"),
      where: 'properties["testGroup"]!="subtext"'
    )["data"]["values"]["signIn"]
    yesterday = (Time.current - 1.day).strftime("%Y-%m-%d")
    @metrics[:sign_ins] = { yesterday: sign_in_data[yesterday] }
    @metrics[:sign_ins][:past_week] = sign_in_data.map{ |k,v| v}.inject(:+)
    
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
        data: ((@metrics[:relevant_clicks][sym] / @metrics[:article_clicks][sym].to_f) * 100).to_i
      }, {
        label: "Landing Clicks: #{@metrics[:landing_clicks][sym]}",
        data: ((@metrics[:landing_clicks][sym] / @metrics[:article_clicks][sym].to_f) * 100).to_i
      }].to_json
    end    
    @yesterday_pie_chart_data = clicks[0]
    @pastweek_pie_chart_data  = clicks[1]

  end

end
