require 'mixpanel-ruby'

class SubtextTracker < Mixpanel::Tracker
  
  alias_method :orig_track, :track
  def track(distinct_id, event, user, properties={})
    if user.present?
      user_props = {}
      user_props['userId'] = user.try(:id)
      user_props['userName'] = user.try(:name)
      user_props['userEmail'] = user.try(:email)
      user_props['userCommunity'] = user.try(:location).try(:name)
      user_props['testGroup'] = user.try(:test_group)

      properties.merge! user_props
    end

    orig_track(distinct_id, event, properties)
  end

  def navigation_properties(channelName,pageName=nil,url,params)
    props = {}
    props['channelName'] = channelName
    props['pageName'] = pageName
    props['url'] = url
    props['pageNumber'] = params[:page] ||  1
    props
  end

  def search_properties(params)
    props = {}
    props['category'] = params[:category] 
    props['searchStartDate'] = params[:start_date]
    props['searchEndDate'] = params[:end_date]
    if params[:location].present?
      props['location'] = Location.find(params[:location]).name
    end
    props['query'] = params[:query]
    props['publication'] = params[:publication]
    props
  end

  def content_properties(content)
    props = {}
    if content.present?
      props['contentId'] = content.try(:id)
      props['contentChannel'] = content.try(:channel_type)
      props['contentLocation'] = content.try(:location)
      props['contentPubdate'] = content.try(:pubdate)
      props['contentTitle'] = content.try(:title)
      props['conentPublication'] = content.try(:publication).try(:name)
    end
    props
  end

  def banner_properties(banner)
    props = {}
    props['bannerAdId'] = banner.try(:id)
    props['bannerUrl'] = banner.try(:redirect_url)
    props
  end

  def content_creation_properties(submitType, inReplyTo=nil)
    props = {}
    props['submitType'] = submitType
    props['inReplyTo'] = inReplyTo
    props
  end
end
