class CurriculumSweeper < ActionController::Caching::Sweeper
  observe Curriculum
 
  def after_update(curriculum)
    expire_cache_for(curriculum)
  end
 
  def after_destroy(curriculum)
    expire_cache_for(curriculum)
  end
 
  private
  def expire_cache_for(curriculum)
    expire_page(:controller => '/curriculums', :action => 'graph', :id => curriculum.id, :format => 'json')
    
    expire_fragment(:controller => 'curriculums', :action => 'index', :action_suffix => 'competence_details')
  end
end 
