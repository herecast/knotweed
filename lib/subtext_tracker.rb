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
      #TODO  user_props['un_registered_id'] = ''

      properties.merge! user_props
    end
    orig_track(distinct_id, event, properties)
  end

  def navigation_properties(channelName,pageName,url,pageNumber)
    props = {}
    props['channelName'] = channelName
    props['pageName'] = pageName
    props['url'] = url
    props['pageNumber'] = pageNumber || 1
    props
  end

  def search_properties(category, start_date, end_date, location, query, publication)
    props = {}
    props['category'] = category
    props['start_date'] = start_date
    props['end_date'] = end_date
    if location.present?
      props['location'] = Location.find(location).name
    end
    props['query'] = query
    props['publication'] = publication
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
end
