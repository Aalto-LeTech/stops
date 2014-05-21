require 'set'

class Plans::CompetencesController < PlansController

  def index
    # OBSOLETE
    authorize! :read, @study_plan
    
    log("view_competences")
    @competences = @curriculum.competences.joins(:competence_descriptions).includes(:localized_description, :skills => [:localized_description]).where(:parent_competence_id => nil, :competence_descriptions => {:locale => I18n.locale}) .order('competence_descriptions.name')
    @chosen_competence_ids = @study_plan.competence_ids.to_set

    render :action => :index, :layout => 'fixed'
  end

  # GET /plans/1/competence/1
  # GET /plans/1/competence/1.xml
  def show
    authorize! :read, @study_plan
    
    @competence = Competence.includes(:localized_description, {:skills => :localized_description}).find(params[:id])
    @chosen_competence_ids = @study_plan.competence_ids.to_set
    
    #@mandatory_courses = @competence.recursive_prereq_courses.includes(:localized_description).all
    #@mandatory_prereqs = @competence.ancestor_prereq_courses.includes(:localized_description).all - @mandatory_courses
    #@supporting_courses = @competence.supporting_prereq_courses.includes(:localized_description).order(:course_code).all - @mandatory_courses
    #@included_courses = @study_plan.scoped_course_ids.to_set
    
    # @passed_courses = Hash.new
    # @study_plan.passed_courses.each do |course|
    #   @passed_courses[course.id] = course
    # end

    # Log
    @client_session_id = SecureRandom.hex(3)
    log("view_competence #{@competence.id} (#{@client_session_id})")
    
    render :action => 'show', :layout => 'leftnav'
  end

  # Prepare to add competence to study plan
  def new
    authorize! :update, @study_plan
    
    @competence_node = CompetenceNode.find(params[:id])
    #authorize! :choose, @competence_node
    
    # If competence is aleady in the plan, don't do anything
    if @study_plan.has_competence?(@competence_node)
      if @competence_node.is_a? Competence
        redirect_to studyplan_competence_path(:id => @competence_node)
      elsif @competence_node.is_a? ScopedCourse
        redirect_to studyplan_course_path(:id => @competence_node)
      end
      return
    end

    # FIXME: plan may contain PlanCourses that are not associated with a ScopedCourse
    existing_courses = @study_plan.scoped_courses
    prereqs = @competence_node.recursive_prereq_courses.includes(:localized_description).all
    @new_courses = prereqs - existing_courses # difference
    @shared_courses = existing_courses & prereqs # intersection
    
    render :action => 'new', :layout => 'fixed'
    
    log("add_competence prepare #{@competence_node.id}")
  end

  # Adds a competence to the study plan
  # POST /plans/1/profiles
  # POST /plans/1/profiles.xml
  def create
    authorize! :update, @study_plan
    competence = Competence.find(params[:competence_id])
    authorize! :choose, competence

    log("add_competence_commit #{competence.id}")
    
    # Dont't do anything if user has already selected this competence
    if @study_plan.has_competence?(params[:competence_id])
      redirect_to studyplan_competence_path(competence), :flash => {:error => t('.competence_already_selected', :name => @competence.localized_name)}
    end

    # Add competence to study plan
    @study_plan.add_competence(competence)

    redirect_to studyplan_competence_path(competence)
  end

  def delete
    authorize! :update, @study_plan
    @competence = Competence.find(params[:id])

    log("remove_competence_prepare #{@competence.id}")
    
    @courses = @study_plan.deletable_scoped_courses(@competence)
  end

  # Removes a profile from the study plan
  # DELETE /plans/1/profiles/1
  # DELETE /plans/1/profiles/1.xml
  def destroy
    authorize! :update, @study_plan
    @competence = Competence.find(params[:id])

    @study_plan.remove_competence(@competence)
    log("remove_competence_commit #{@competence.id}")

    respond_to do |format|
      format.html { redirect_to studyplan_competence_path(@competence) }
      format.xml  { head :ok }
    end
  end

  def supporting
    authorize! :read, @study_plan
    
    @competence = Competence.includes(
                    :courses,
                    :courses => {
                      :skills => [
                        :supporting_prereqs,
                        { :supporting_prereqs => :competence_node }
                      ]
                    }).find(params[:id])
    log("view_competence_supporting #{@competence.id}")

    @supporting_courses = {}  # scoped_course_id => credits

    @competence.courses.each do |course|
      course.skills.each do |skill|
        skill.supporting_prereqs.each do |supporting_skill|

          competence_node = supporting_skill.competence_node

          @supporting_courses[competence_node] ||= 0.0
          @supporting_courses[competence_node] += supporting_skill.credits
        end
      end
    end
  end

end

