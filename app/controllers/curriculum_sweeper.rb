class CurriculumSweeper < ActionController::Caching::Sweeper
  observe Curriculum
 
  #def after_create(curriculum)
  #end
 
  def after_update(curriculum)
    expire_cache_for(curriculum)
  end
 
  # If our sweeper detects that a Product was deleted call this
  def after_destroy(curriculum)
    expire_cache_for(curriculum)
  end
 
  private
  def expire_cache_for(curriculum)
    logger.info "========= Expire #{curriculum.id} ========="
    expire_page(:controller => '/curriculums', :action => 'graph', :id => curriculum.id, :format => 'json')
  end
end 
