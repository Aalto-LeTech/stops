class Curriculums::SkillsController < CurriculumsController

  before_filter :load_curriculum

  respond_to :json, :only => 'index'

  def index
    @skills = Skill.where(:skillable_id => @curriculum.course_ids).joins(:skill_descriptions).where(["skill_descriptions.locale = ?", I18n.locale]).select("skills.id, skills.skillable_id, skills.skillable_type, skills.position, skill_descriptions.description AS translated_name").includes(:strict_prereqs)
    # :skillable_type => 'ScopedCourse'
      #.includes(:strict_prereqs)


    respond_to do |format|
      #format.html { render :text => @skills.to_json(:include => :strict_prereq_ids) }
      format.xml { render :xml => @skills }
      format.json { render :json => @skills.to_json(:methods => :strict_prereq_ids) }
    end
  end

  # GET curriculum/:id/skills/:id
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

  def new
    @skill = Skill.new
    @skill.skillable = Competence.find(params[:competence_id])
   
    # Create empty descriptions for each required locale
    REQUIRED_LOCALES.each do |locale| 
      @skill.skill_descriptions << SkillDescription.new(:locale => locale)
    end

    respond_to do |format|
      format.js
    end
  end
  
  # POST /curriculum/:id/skills
  def create
    @skill = Skill.new(params[:skill])

    respond_to do |format|
      format.js { @skill.save! }
    end
  end

  # POST /add_prereq
  def add_prereq
    SkillPrereq.create :skill_id     => Integer(params[:id]), 
                       :prereq_id    => Integer(params[:prereq_id]), 
                       :requirement  => STRICT_PREREQ

    render :nothing => true
  end

  # POST /remove_prereq
  def remove_prereq
    @prereq = SkillPrereq.where "skill_id = ? AND prereq_id = ?", 
                params[:id], params[:prereq_id]

    @prereq.first.destroy
    render :nothing => true
  end

  # GET /:id/edit
  def edit
    respond_to do |format|
      format.html do 
        #render "edit_skill_prereqs.js.erb"

        # Validate query string key
        render(:nothing => true, :status => 500) unless /^\d+$/ =~ params[:id] 

        # Find all courses within curriculum that have at least one skill as a
        # a prerequirement to the skill being edited
        @prereq_courses = ScopedCourse.find(
                            :all, 
                            :conditions => [
                              'curriculum_id = ? AND "skill_prereqs"."skill_id" = ?', 
                              params[:curriculum_id], params[:id]
                            ], 
                            :include => [
                              :course_description_with_locale,
                              { :skills => [:prereq_to, :description_with_locale] } 
                            ]
                          )

        @skill = Skill.includes(:description_with_locale).find(params[:id].to_i)

        # Render an eco template for each course (This is done to use the same template
        # for Javascript view updates)
        eco_template_path = File.join(Rails.root, 
          "app/assets/javascripts/templates/_current_course_with_prereq_skills.jst.eco")
        eco_template = File.read(eco_template_path)

        @courses_rendered = []
        @prereq_courses.each do |course|
          skills = []
          course.skills.each do |skill|
            skill_locals = {
              :description  => skill.description_with_locale.description,
              :id           => skill.id,
              :is_prereq    => skill.is_prereq_to?(@skill.id)
            }
            skills << skill_locals
          end
          locals = {
            :render_whole_course  => true,
            :course_id            => course.id, 
            :course_code          => course.code,
            :course_name          => course.course_description_with_locale.name,
            :course_skills        => skills,
            :button_text          => t(:competence_skill_add_prereq_button_remove)
          }

          @courses_rendered << Eco.render(eco_template, locals)
        end

        @skill_id = params[:id]
      end 
    end
  end
  

  # Action for retrieving courses that match certain search terms
  # using AJAX.
  # GET /curriculum/:id/skills/:id/
  def search_skills_and_courses
    # @courses = ScopedCourse.includes(:course_description_with_locale, :skill_descriptions).search_full_text params[:q] 
    
    @courses = ScopedCourse.search params[:q], 
                  :include  => [:course_description_with_locale, :skill_descriptions_with_locale],
                  :page     => params[:p] || 1, :per_page => 20

    # Validate skill_id!
    render(:nothing => true, :status => 500) unless /^\d+$/ =~ params[:sid] 

    skill_id = params[:sid]

    # Query to find out if skills are already prerequirements to the
    # skill being edited.
    queryresults = ActiveRecord::Base.connection.select_all %Q{
      SELECT DISTINCT ON (skills.id) skills.id, skills.id IN (
        SELECT skill_prereqs.prereq_id 
        FROM skills 
        INNER JOIN skill_prereqs ON skills.id = skill_prereqs.prereq_id
        WHERE skills.skillable_type = 'ScopedCourse' 
        AND skill_prereqs.skill_id = #{skill_id}
      ) AS alreadyPrereq
      FROM skills
    }

    # Lookup table for view to check if skill is already a prerequirement
    @alreadyPrereq = { }
    queryresults.each do |row|
      @alreadyPrereq[row["id"]] = row["alreadyprereq"] == 't' ? true : false
    end

    # Slow down request for testing
    # sleep 1.5

    if @courses.empty?
      respond_to do |format|
        format.text { render :text => "nothing" }
      end
    else
      respond_to do |format|
        format.html { render :partial => "search_results" }
      end
    end
  end

end
