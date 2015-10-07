require 'mixpanel-ruby'

class SubtextTracker < Mixpanel::Tracker
  
  alias_method :orig_track, :track
  def track(distinct_id, event, user, properties={})
    user_props = {}
    user_props['userId'] = user.try(:id)
    user_props['userName'] = user.try(:name)
    user_props['userEmail'] = user.try(:email)
    user_props['userCommunity'] = user.try(:location).try(:name)
    user_props['testGroup'] = user.try(:test_group)
    #TODO  user_props['un_registered_id'] = ''

    properties.merge! user_props
    orig_track(distinct_id, event, properties)
  end
end
