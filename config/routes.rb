ActionController::Routing::Routes.draw do |map|
  
  scope ":locale" do
    devise_for :users

    match '/preferences' => 'users#edit'
    resources :users
    
    #resources :courses  # AbstreactCourses
    
    resources :course_instances
    
    resources :skills do
      member do 
        get 'prereqs'
        get 'future'
        get 'profilepath'
      end
    end
    
    # View study guides of other years
    resources :curriculums, :constraints => { :id => /\w+/ } do
      member do
        get 'cycles'
        get 'prereqs'
      end
      
      resources :profiles, :controller => 'curriculums/profiles'
      resources :courses, :controller => 'curriculums/courses'  # ScopedCourses
    end

    # My Plan
    resource :studyplan, :controller => 'plans' do
      resources :profiles, :controller => 'plans/profiles', :except => [:edit, :update] do
        member do
          get :delete
        end
        
        resources :courses, :controller => 'plans/courses', :only => [:show]  # ScopedCourses, courses that belong to the profile
      end
      
      resources :courses, :controller => 'plans/courses', :except => [:edit, :update]  # ScopedCourses, courses that i have selected
      resource :schedule, :controller => 'plans/schedule'
      resource :record, :controller => 'plans/record'
      
      resource :curriculum, :controller => 'plans/curriculums'
    end
    
    # Any plan (specify student ID)
    resources :plans, :constraints => { :id => /\w+/ } do
      resources :profiles, :controller => 'plans/profiles', :except => [:edit, :update]
      resources :courses, :controller => 'plans/courses', :except => [:edit, :update]
      resource :schedule, :controller => 'plans/schedule'
      resource :record, :controller => 'plans/record'
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
