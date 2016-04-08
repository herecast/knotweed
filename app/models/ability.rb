class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # cycle through the user's roles and apply appropriate permissions
    
    if user.has_role? :admin # super admin, unscoped to a resource
      can :manage, :all
      can :access, :dashboard
    elsif user.has_role? :event_manager
      can :access, :dashboard
      # give access only to event category contents
      event_category = ContentCategory.find_or_create_by(name: "event")
      can :manage, Content, content_category_id: event_category.id
      can :manage, BusinessLocation # for event venues
      can :manage, Content, created_by: user
    else
      if Role.where(name: 'manager').count > 0
        managed_orgs = Organization.with_role(:manager, user)
      else
        managed_orgs = []
      end
      if managed_orgs.present?
        # note: due to quirks in the way Rolify works, we *can't* use the same role name for this
        # that we use for the unscoped admin. So instead I'm calling it manager.
        parent_org_ids = managed_orgs.pluck(:id)
        org_ids = (parent_org_ids + managed_orgs.map{|o|o.get_all_children}.flatten.map{|o|o.id}).uniq
        can :manage, Organization, id: org_ids
        can :manage, Content, organization_id: org_ids
        can :access, :admin if managed_orgs.present? # allow basic access if they have some management position
      end

      # all users can manage their own content
      can :manage, Content, created_by: user
    end
  end
end
