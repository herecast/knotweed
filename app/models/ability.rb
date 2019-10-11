# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # cycle through the user's roles and apply appropriate permissions

    if user.has_role? :admin # super admin, unscoped to a resource
      can :manage, :all
      cannot :crud, Content
      can :crud, Content do |content|
        user.managed_organizations.map(&:id).include?(content.organization_id)
      end
      can :crud, Content, created_by: user
      can :access, :dashboard
      can :access, :rails_admin
      can :access, :admin
    elsif user.has_role? :event_manager
      can :access, :dashboard

      can :manage, Content, created_by: user
      can :manage, Content, content_category: 'event'

      # Hashie::Mash is returned directly out of searchkick when {load: false}
      can :manage, Hashie::Mash, _type: 'content', created_by: { id: user.id }
      can :manage, Hashie::Mash, _type: 'content', content_category: 'event'

      can :manage, BusinessLocation # for event venues
    else
      managed_orgs = if user.roles.where(name: 'manager').count > 0
                       Organization.with_role(:manager, user)
                     else
                       []
                     end
      if managed_orgs.present?
        # note: due to quirks in the way Rolify works, we *can't* use the same role name for this
        # that we use for the unscoped admin. So instead I'm calling it manager.
        parent_org_ids = managed_orgs.pluck(:id)
        org_ids = (parent_org_ids + managed_orgs.map(&:get_all_children).flatten.map(&:id)).uniq
        can :manage, Organization, id: org_ids
        can :manage, PromotionBanner, promotion: { content: { organization_id: org_ids } }
        can :manage, Content, organization_id: org_ids
        can :manage, Hashie::Mash, _type: 'content', organization_id: org_ids
        can :manage, Hashie::Mash, _type: 'event_instance', organization_id: org_ids

        can :access, :admin if managed_orgs.present? # allow basic access if they have some management position
      end

      can :manage, PromotionBanner, promotion: { created_by: user }
      can :manage, Content, created_by: user
      can :manage, Comment, created_by: user
      can :manage, UserBookmark, user: user
      can :manage, user
      can :create, Organization
      can :manage, Hashie::Mash, _type: 'content', created_by: { id: user.id }
      can :manage, Hashie::Mash, _type: 'event_instance', created_by: { id: user.id }
    end
  end
end
