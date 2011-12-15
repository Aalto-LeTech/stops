class Curriculums::SkillsController < CurriculumsController

  before_filter :load_curriculum

  respond_to :json, :only => 'index'

  def index
    @skills = Skill.where(:skillable_id => @curriculum.course_ids, :skillable_type => 'ScopedCourse').joins(:skill_descriptions).where(["skill_descriptions.locale = ?", I18n.locale]).select("skills.id, skills.skillable_id, skills.skillable_type, skills.position, skill_descriptions.description AS translated_name").includes(:strict_prereqs)
      #.includes(:strict_prereqs)


    respond_to do |format|
      #format.html { render :text => @skills.to_json(:include => :strict_prereq_ids) }
      format.xml { render :xml => @skills }
      format.json { render :json => @skills.to_json(:methods => :strict_prereq_ids) }
    end
  end

  # GET /courses/1
  # GET /courses/1.xml
  def show
    @skill = Skill.find(params[:id])

    @competence = Competence.find(params[:competence_id]) if params[:competence_id]
    @profile = @competence.profile

    @courses = @skill.contributing_skills

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @skill }
    end
  end



end
