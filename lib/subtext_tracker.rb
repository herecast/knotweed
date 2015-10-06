require 'mixpanel-ruby'

class SubtextTracker < Mixpanel::Tracker
  
  def trail(distinct_id, event, user, properties={})
    user_props = {}
    user_props['user_id'] = user.try(:id)
    user_props['user_name'] = user.try(:name)
    user_props['user_email'] = user.try(:email)
    user_props['community'] = user.try(:location).try(:name)
    user_props['test_group'] = user.try(:test_group)
    #TODO  user_props['un_registered_id'] = ''

    properties.merge! user_props

    track(distinct_id, event, properties)
  end
end
