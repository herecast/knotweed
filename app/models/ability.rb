class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.has_role? :admin
      can :access, :dashboard
      can :manage, :all
      # can :access, :admin
    elsif user.has_role? :event_manager
      can :access, :dashboard
      # give access only to event category contents
      event_category = ContentCategory.find_or_create_by_name("event")
      can :manage, Content, content_category_id: event_category.id
      can :manage, BusinessLocation # for event venues
    elsif user.organization
      can [:update, :read], Organization, :id => user.organization_id
      can :manage, Publication, :organization_id => user.organization_id
      can :manage, ImportJob, :organization_id => user.organization_id
      can :manage, Parser, :organization_id => user.organization_id
      can :access, :admin
    end
      
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
