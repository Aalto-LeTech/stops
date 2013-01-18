class Ability
  include CanCan::Ability

  def initialize(user)
    # All users, including unauthenticated
    can :read, Curriculum
    can :create, User

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

    # Staff
    if user.staff?
      can :create, Curriculum
    end

    # Admin
    if user.admin?
      can :manage, :all
    end

    # Curriculum roles
    can [:update], Curriculum do |curriculum|
      curriculum.has_admin?(user) || curriculum.has_teacher?(user)
    end
    
    can [:destroy], Curriculum do |curriculum|
      curriculum.has_admin? user
    end
  end
end
