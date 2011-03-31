class Ability
  include CanCan::Ability

  def initialize(user)
    # All users, including unauthenticated
    can :read, Curriculum
    
    # Authenticated users
    return unless user
    
    # Any authenticated user
    can :choose, Profile
    can :choose, ScopedCourse
    
    # Admin
    if user.admin?
      can :update, :all
      can :create, :all
      can :destroy, :all
    end
  end
end
