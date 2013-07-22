class Ability
  include CanCan::Ability

  def initialize(user)
    # All users, including unauthenticated
    can :read, Curriculum
    can :create, User

    # Authenticated users
    return unless user

    # Any authenticated user
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
    can [:destroy, :import], Curriculum do |curriculum|
      curriculum.has_admin?(user)
    end

    can [:update, :create_course], Curriculum do |curriculum|
      curriculum.has_admin?(user) || curriculum.has_teacher?(user)
    end

    can [:update, :destroy], Competence do |competence|
      competence.curriculum.has_admin?(user) || competence.curriculum.has_teacher?(user)
    end

    can [:update, :destroy], ScopedCourse do |scoped_course|
      scoped_course.curriculum.has_admin?(user) || scoped_course.curriculum.has_teacher?(user)
    end


    # Studyplan
    can [:read, :update], StudyPlan do |plan|
      plan.user = user
    end

  end
end
