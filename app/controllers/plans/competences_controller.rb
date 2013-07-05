require 'set'

class Plans::CompetencesController < PlansController

  include CompetencesHelper

  #before_filter :login_required
  before_filter :load_plan

  def index
    @chosen_competence_ids = @study_plan.competence_ids.to_set
  end

  # GET /plans/1/competence/1
  # GET /plans/1/competence/1.xml
  def show
    @competence = Competence.find(params[:id])

    @included_courses = @study_plan.courses

    @passed_courses = Hash.new
    @user.user_courses.each do |course|
      @passed_courses[course.id] = course
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @competence }
    end
  end

  # Prepare to add competence to study plan
  def new
    @competence = Competence.find(params[:id])
    authorize! :choose, @competence

    # If competence is aleady in the plan, don't do anything
    if @study_plan.has_competence?(@competence)
      redirect_to studyplan_profiles_path, :flash => {:error => t(:profile_already_selected, :name => @competence.name(I18n.locale))}
      return
    end

    user_courses = @study_plan.courses
    @new_courses = @competence.courses_recursive - user_courses # difference
    @existing_courses = user_courses & @competence.strict_prereqs # intersection
  end

  # Adds a competence to the study plan
  # POST /plans/1/profiles
  # POST /plans/1/profiles.xml
  def create
    competence = Competence.find(params[:competence_id])
    authorize! :choose, competence

    # Dont't do anything if user has already selected this competence
    if @study_plan.has_competence?(params[:competence_id])
      redirect_to studyplan_competence_path( competence ), :flash => {:error => t('.competence_already_selected', :name => @competence.name(I18n.locale))}
    end

    # Add competence to study plan
    @study_plan.add_competence(competence)

    redirect_to studyplan_competence_path( competence )
  end

  def delete
    @competence = Competence.find(params[:id])

    # TODO: authorize! :edit, @user

    @courses = @study_plan.deletable_courses(@competence)
  end

  # Removes a profile from the study plan
  # DELETE /plans/1/profiles/1
  # DELETE /plans/1/profiles/1.xml
  def destroy
    @competence = Competence.find(params[:id])

    # TODO: authorize

    @study_plan.remove_competence(@competence)

    respond_to do |format|
      format.html { redirect_to studyplan_competence_path(@competence) }
      format.xml  { head :ok }
    end
  end

  def supporting
    @competence = Competence.includes(
                    :courses, 
                    :courses => { 
                      :skills => [
                        :supporting_prereqs,
                        { :supporting_prereqs => :competence_node }
                      ] 
                    }).find(params[:id])


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


  def add_competence_to_plan
    if is_non_negative_integer params[:id]
      id = params[:id].to_i
      competence = Competence.find id
      if competence && @study_plan.curriculum_id == competence.curriculum_id
        @study_plan.competences << competence

        render :nothing => true
      else
        render :nothing => true, :status => 403
      end
    else
      render :nothing => true, :status => 403
    end
  end



  def remove_competence_from_plan
    if is_non_negative_integer params[:id]
      id = params[:id].to_i
      competence = @study_plan.competences.find id

      if competence
        @study_plan.competences.delete competence

        render :nothing => true
      else
        render :nothing => true, :status => 403
      end
    else
      render :nothign => true, :status => 403
    end
  end

end
