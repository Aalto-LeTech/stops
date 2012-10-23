class Ability
  include CanCan::Ability

  def initialize(user)
    # All users, including unauthenticated
    can :read, Curriculum
    
    # Authenticated users
    return unless user
    
    # Any authenticated user
    can :choose, Profile
    can :choose, Competence
    can :read, Competence
    can :choose, ScopedCourse
    can :read, Skill
    
    # User can edit own preferences
    can [:read, :update], User, :id => user.id
    
    # Admin
    if user.admin?
      can :manage, :all
    end
  end
end
