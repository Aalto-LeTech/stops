class Plans::CompetencesController < PlansController
  
  #before_filter :login_required
  before_filter :load_plan
  before_filter :load_curriculum
  
  
  def load_plan
    @user = current_user
  end
  
  # Prepare to add competence to studyplan
  def new
    @competence = Competence.find(params[:id])
    authorize! :choose, @competence
    
    # If profile is aleady in the plan, don't do anything
    if @user.has_competence?(@competence.id)
      redirect_to studyplan_profiles_path, :flash => {:error => t(:profile_already_selected, :name => @competence.name(I18n.locale))}
      return
    end
    
    user_courses = @user.courses
    @new_courses = @competence.courses_recursive - user_courses # difference
    @existing_courses = user_courses & @competence.strict_prereqs # intersection
  end

  # Adds a competence to the study plan
  # POST /plans/1/profiles
  # POST /plans/1/profiles.xml
  def create
    competence = Competence.find(params[:competence_id])
    authorize! :choose, competence
    
    # Dont't do anything if user has already selected this profile
    if @user.has_competence?(params[:competence_id])
      redirect_to studyplan_profile_url(:id => competence.profile.id), :flash => {:error => t(:profile_already_selected, :name => @competence.name(I18n.locale))}
    end
    
    # Add profile to study plan
    @user.add_competence(competence)
    
    redirect_to studyplan_profile_url(:id => competence.profile.id)
  end

  def delete
    @competence = Competence.find(params[:id])
    
    # TODO: authorize! :edit, @user
    
    @courses = @user.deletable_courses(@competence)
  end
  
  # Removes a profile from the study plan
  # DELETE /plans/1/profiles/1
  # DELETE /plans/1/profiles/1.xml
  def destroy
    @competence = Competence.find(params[:id])
    
    # TODO: authorize
    
    @user.remove_competence(@competence)

    respond_to do |format|
      format.html { redirect_to studyplan_profile_url(:id => @competence.profile.id) }
      format.xml  { head :ok }
    end
  end
end
