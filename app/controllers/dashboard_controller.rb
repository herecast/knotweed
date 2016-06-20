require 'google/api_client'
require 'oauth2'

class DashboardController < ApplicationController

  @@mixpanel = Mixpanel::Client.new(
    api_key: Figaro.env.mixpanel_api_key,
    api_secret: Figaro.env.mixpanel_api_secret
  )

  def index
    authorize! :access, :dashboard
  end

  def session_duration

    params[:session_duration_time_frame] = params[:time_frame]

    # can't use process_time_frame because the method takes a different format from mixpanel
    if !params[:time_frame].present? or params[:time_frame] == "month"
      @from_date = 1.month.ago
      dimensions = :date
    elsif params[:time_frame] == "week"
      @from_date = 1.week.ago
    elsif params[:time_frame] == "day"
      @from_date = 1.day.ago
    else
      @from_date = 1.month.ago #default
    end

    user = service_account_user
    profile = user.profiles.first
    @results = GaSession.results(profile, start_date: @from_date)
    if params[:time_frame] == "day"
      @results.dimensions << :hour
    else
      @results.dimensions << :date
    end

    result_hash = {}
    @results.each do |r|
      if r.try(:hour).present?
        date = DateTime.parse("#{Date.current.strftime("%Y%m%d ")} #{r.hour}")
        result_hash[date] = r.avgSessionDuration.to_f
      else
        date = DateTime.parse(r.date)
        result_hash[date] = r.avgSessionDuration.to_f
      end
    end
    @r = result_hash

    results_array = []
    result_hash.each do |k,v|
      results_array.push([k.to_i*1000, v/60])
    end
    @session_duration_json = [results_array].to_json

    render partial: "dashboard/session_duration"
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

  def clicks_by_category
    process_time_frame

    params[:clicks_by_category_time_frame] = params[:time_frame]
    # unfortunately, we can't get sums for different properties with one query
    # from the mixpanel api, so we have to make a request for each category.
    click_data = []
    ContentCategory.all.each do |cc|
      # skip categories with no content
      if cc.contents.count == 0 or cc.name.empty?
        next
      end
      landing_clicks = @@mixpanel.request(
        'segmentation',
        event: "clickLandingLink",
        from_date: @from_date,
        unit: "day", # we just want the sum so why deal with shorter units
        to_date: Time.zone.now.strftime("%Y-%m-%d"),
        where: ('properties["testGroup"]!="subtext" and properties["docChannel"] == "' + cc.name + '"')
      )["data"]["values"]["clickLandingLink"]
      relevant_clicks = @@mixpanel.request(
        'segmentation',
        event: "clickRelevantLink",
        from_date: @from_date,
        unit: "day", # we just want the sum so why deal with shorter units
        to_date: Time.zone.now.strftime("%Y-%m-%d"),
        where: ('properties["testGroup"]!="subtext" and properties["docChannel"] == "' + cc.name + '"')
      )["data"]["values"]["clickRelevantLink"]

      sum = 0
      [landing_clicks, relevant_clicks].each do |h|
        if h.present?
          h.each do |k,v|
            sum += v
          end
        end
      end

      if sum > 0
        click_data.push([cc.name.titlecase, sum])
      end
    end
    @clicks_by_category_json = [click_data].to_json

    render partial: "dashboard/clicks_by_category"
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
  
  def service_account_user(scope="https://www.googleapis.com/auth/analytics.readonly")
    client = Google::APIClient.new(
      :application_name => "Subtext",
      :application_version => "0.1.5"
    )
    key = Google::APIClient::KeyUtils.load_from_pkcs12("#{Rails.root}/config/ga_key.p12", "notasecret")
    service_account = Google::APIClient::JWTAsserter.new("614656289384-k0nmd03lltqqf2pvfks267fb1csdj4j6@developer.gserviceaccount.com", scope, key)
    client.authorization = service_account.authorize
    oauth_client = OAuth2::Client.new("", "", {
      :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
      :token_url => 'https://accounts.google.com/o/oauth2/token'
    })
    token = OAuth2::AccessToken.new(oauth_client, client.authorization.access_token, expires_in: 1.hour)
    user = Legato::User.new(token)
  end

end
