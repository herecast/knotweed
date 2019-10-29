# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # cycle through the user's roles and apply appropriate permissions

    if user.has_role? :admin # super admin, unscoped to a resource
      can :manage, :all
      cannot :crud, Content
      can :crud, Content, created_by: user
      can :access, :dashboard
      can :access, :rails_admin
      can :access, :admin
    else
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
