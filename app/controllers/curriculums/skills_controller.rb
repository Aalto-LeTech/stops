class Curriculums::SkillsController < CurriculumsController

  before_filter :load_curriculum

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
