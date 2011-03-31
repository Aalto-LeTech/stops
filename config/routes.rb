ActionController::Routing::Routes.draw do |map|
  
  scope ":locale" do
    resource :session do
      get 'shibboleth'
    end
    match '/login' => 'sessions#new', :as => :login
    match '/logout' => 'sessions#destroy', :as => :logout
  
    match '/preferences' => 'users#edit'
    resources :users
    
    #resources :courses  # AbstreactCourses
    
    resources :course_instances, :only => [:index]
    
    resources :skills do
      member do 
        get 'prereqs'
        get 'future'
        get 'profilepath'
        post 'matrix'
      end
    end
    
    resources :profiles, :only => [:destroy] do
      resources :competences
    end
    
    # View study guides of other years
    resources :curriculums, :constraints => { :id => /\w+/ } do
      member do
        get 'cycles'
        get 'prereqs'
        get 'graph'
      end
      
      resources :profiles, :controller => 'curriculums/profiles' do
        resources :courses, :controller => 'curriculums/courses', :only => [:show]  # ScopedCourses, courses that belong to the profile
      end
      
      resources :competences, :controller => 'curriculums/competences', :only => [:show, :edit, :update]
      
      resources :courses, :controller => 'curriculums/courses', :only => [:index, :show]  # ScopedCourses
    end

    # My Plan
    resource :studyplan, :controller => 'plans', :only => [:show] do
      resources :profiles, :controller => 'plans/profiles', :except => [:edit, :update] do
        member do
          get :delete
        end
        
        resources :courses, :controller => 'plans/courses', :only => [:show]  # ScopedCourses, courses that belong to the profile
      end
      
      resources :courses, :controller => 'plans/courses', :except => [:edit, :update]  # ScopedCourses, courses that i have selected
      resource :schedule, :controller => 'plans/schedule', :only => [:show, :edit]
      resource :record, :controller => 'plans/record', :only => [:show]
      
      resource :curriculum, :controller => 'plans/curriculums', :only => [:show, :edit, :update]
    end
    
    # Any plan (specify student ID)
    resources :plans, :constraints => { :id => /\w+/ }, :only => [:show] do
      resources :profiles, :controller => 'plans/profiles', :except => [:edit, :update]
      resources :courses, :controller => 'plans/courses', :except => [:edit, :update]
      resource :schedule, :controller => 'plans/schedule', :only => [:show, :edit]
      resource :record, :controller => 'plans/record', :only => [:show]
    end
    
#     scope "/:curriculum_id" do
#       resources :courses do  # scoped courses
#         member do
#           get 'graph'
#         end
#       end
#       
#       resources :profiles do
#         resources :courses, :controller => 'profiles/courses'
#       end
#     end
    
  end
  
  match '/:locale' => "frontpage#index"
  root :to => "frontpage#index"
  
end
