require 'set'

class Plans::SkillsController < PlansController

  before_filter :load_plan

  # GET /studyplan/courses/1
  # GET /studyplan/courses/1.xml
  def show
    authorize! :read, @study_plan
    @skill = Skill.find(params[:id])
    @competence = Competence.find(params[:competence_id])
    
    @prereq_ids = @skill.prereq_ids.to_set
    @prereq_courses = @skill.prereq_courses.uniq
    
    log("view_skill #{skill.id}")
  end

end
