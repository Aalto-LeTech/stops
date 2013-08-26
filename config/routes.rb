Ops::Application.routes.draw do
  scope ":locale" do
    resource :session do
      get 'shibboleth'
    end
    match '/login' => 'sessions#new', :as => :login, :via => :get
    match '/login' => 'sessions#create', :via => :post
    match '/logout' => 'sessions#destroy', :as => :logout

    match '/preferences' => 'users#edit'
    resources :users do
      member do
        get :courses
      end
    end

    #resources :courses  # AbstractCourses

    resources :course_instances, :only => [:index]

    resources :skills do
      member do
        get 'prereqs'
        get 'future'
        get 'competencepath'
      end
    end

    # View study guides of other years
    resources :curriculums, :constraints => { :id => /\w+/ } do
      member do
        get 'cycles'
        get 'prereqs'
        get 'graph'
        get 'outcomes'
        get 'search_skills'
        get 'search_courses'
        match 'edit/import_csv', :controller => 'curriculums', :action => :import_csv, :via => [:post, :get]
      end

      resources :competence_nodes, :controller => 'curriculums/competence_nodes' do
        collection do
          get 'nodes_by_skill_ids'
        end
      end

      resources :competences, :controller => 'curriculums/competences' do
        member do
          get 'contributors'
          get 'graph'
          post 'matrix'
          get 'edit_prereqs'
        end

        resources :skills, :controller => 'curriculums/skills', :only => :show
      end

      resources :courses, :controller => 'curriculums/courses' do  # ScopedCourses
        member do
          get 'prereqs'
          get 'edit_prereqs'
          get 'edit_as_a_prereq'
          get 'comments'
          post 'create_comment'
          get 'graph'
        end
      end

      resources :skills, :controller => 'curriculums/skills' do
        member do
          post 'add_prereq'
          post 'remove_prereq'
          get 'search_skills_and_courses'
          put 'update_position'
        end
      end

      resources :roles, :controller => 'curriculums/roles', :only => [:new, :index, :create, :destroy]

      resources :temp_courses, :controller => 'curriculums/temp_courses'
    end

    # My Plan
    resource :studyplan, :controller => 'plans', :only => [:show] do

      resources :competences,
        :controller => 'plans/competences',
        :only => [:index, :show, :new, :delete, :create, :destroy] do

        # ScopedCourses that belong to the competence
        resources :courses,
          :controller => 'plans/courses',
          :only => [:show]

        member do
          get 'supporting'
          get 'delete'
        end

        collection do
          get 'add_competence_to_plan'
          get 'remove_competence_from_plan'
        end
      end

      # The studyplan courses controller
      resources :courses,
        :controller => 'plans/courses',
        :only => [:index, :show, :create]

      # The studyplan schedule controller
      resource :schedule, :controller => 'plans/schedule', :only => [:show]

      # The studyplan curriculum controller
      resource :curriculum, :controller => 'plans/curriculums', :only => [:show, :edit, :update]
    end

    # Any plan (specify student ID)
    resources :plans, :constraints => { :id => /\w+/ }, :only => [:show, :update] do
      get 'old_schedule', as: 'old_schedule'
      resources :courses, :controller => 'plans/courses', :only => [:index, :show, :create]  # :except => [:edit, :update]
      resource :schedule, :controller => 'plans/schedule', :only => [:show, :edit]
      resource :record, :controller => 'plans/record', :only => [:show]
    end

  end

  resources :invitations, :only => [:show, :destroy], :id => /[^\/]+/

  #match '/:locale' => "plans/schedule#show", :as => :frontpage  # Added a redirect instead
  match '/:locale' => "frontpage#index", :as => :frontpage
  root :to => "application#redirect_by_locale"

end
