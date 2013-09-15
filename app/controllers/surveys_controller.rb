# encoding: UTF-8
class SurveysController < ApplicationController
  before_filter :authenticate_user
  before_filter :load_plan

  layout 'views/surveys'
  
  def load_plan
    @user = current_user

    @study_plan = @user.study_plan
    unless @study_plan
      log('survey_error no studyplan')
      redirect_to root_url
      return false
    end

    @curriculum = @user.study_plan.curriculum
  end
  
  def show
    redirect_to root_url if SurveyAnswer.exists?(:user_id => @user.id)
    
    @motivation_questions = [
      {:id => 40, :course_code => 'Mat-0.123', :name => 'Matematiikka 1'},
      {:id => 41, :course_code => 'Eng-1.632', :name => 'Statiikka'}
    ]
    
    case params[:id]
    when 'treatment'
      @survey_id = TREATMENT_GRAPH
      render :action => 'treatment'
    when 'control'
      @survey_id = TREATMENT_TRADITIONAL
      render :action => 'control'
    else
    end
  end
  
  def create
    @answers = SurveyAnswer.new
    
    @answers.user = current_user
    @answers.studentnumber = current_user.studentnumber
    @answers.login = current_user.login
    @answers.survey_id = params[:survey_id]
    @answers.payload = (params[:questions] || {}).to_json
    @answers.save
    
    # TODO:
    @user.treatment = nil
    @user.save
    
    flash[:success] = 'Kiitos osallistumisestasi tutkimukseen! Järjestelmän kaikki toiminnallisuudet ovat nyt käytettävissäsi.'
    redirect_to studyplan_competences_path()
  end

end
