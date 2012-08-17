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
    
    # Admin
    if user.admin?
      can :read, :all
      can :update, :all
      can :create, :all
      can :destroy, :all
    end
  end
end
