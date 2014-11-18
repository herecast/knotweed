class DashboardController < ApplicationController

    @@mixpanel = Mixpanel::Client.new(
      api_key: Figaro.env.mixpanel_api_key,
      api_secret: Figaro.env.mixpanel_api_secret
    )

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

end
