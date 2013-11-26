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
    # if SurveyAnswer.exists?(:user_id => @user.id)
    #   redirect_to root_url
    #   return
    # end

    @survey_id = @user.treatment
    chosen_competence_ids = @study_plan.competence_ids
    chosen_course_ids = @study_plan.scoped_course_ids
    
    if chosen_competence_ids.include?(73) # ENY
      @major_name = 'Energia- ja ympäristötekniikan'
      @major_id = 73
      @usefulness_questions = [
        {:id => 9, :course_code => 'PHYS-A3120', :name => 'Termodynamiikka (ENG)'},
        {:id => 44, :course_code => 'KJR-C2004', :name => 'Materiaalitekniikka'},
        {:id => 66, :course_code => 'YYT-C2001', :name => 'Hydrologian ja hydrauliikan perusteet'},
        {:id => 13, :course_code => 'MS-A030x', :name => 'Differentiaali- ja integraalilaskenta 3'}
      ]
      @motivation_questions = [
        {:id => 9, :course_code => 'PHYS-A3120', :name => 'Termodynamiikka (ENG)'},
        {:id => 44, :course_code => 'KJR-C2004', :name => 'Materiaalitekniikka'}
      ]
      @motivation_questions << {:id => 66, :course_code => 'YYT-C2001', :name => 'Hydrologian ja hydrauliikan perusteet'} if chosen_course_ids.include?(66)
      @motivation_questions << {:id => 13, :course_code => 'MS-A030x', :name => 'Differentiaali- ja integraalilaskenta 3'} if chosen_course_ids.include?(13)
      
    elsif chosen_competence_ids.include?(59) # KJR
      @major_name = 'Kone- ja rakennustekniikan'
      @major_id = 59
      @usefulness_questions = [
        {:id => 9, :course_code => 'PHYS-A3120', :name => 'Termodynamiikka (ENG)'},
        {:id => 4, :course_code => 'KJR-C2001', :name => 'Kiinteän aineen mekaniikan perusteet'},
        {:id => 13, :course_code => 'MS-A030x', :name => 'Differentiaali- ja integraalilaskenta 3'},
        {:id => 52, :course_code => 'KON-C3001', :name => 'Koneenrakennustekniikka A'}
        # {:id => 6, :course_code => 'ENY-C2001', :name => 'Termodynamiikka ja lämmönsiirto'},
        # {:id => 12, :course_code => 'MS-A020x', :name => 'Differentiaali- ja integraalilaskenta 2'},
        # {:id => 49, :course_code => 'RAK-C3003', :name => 'Tietoyhdennetty rakentaminen'},
        # {:id => 48, :course_code => 'KON-C3004', :name => 'Kone- ja rakennustekniikan laboratoriotyö'}
      ]
      
      @motivation_questions = [
        {:id => 9, :course_code => 'PHYS-A3120', :name => 'Termodynamiikka (ENG)'},
        {:id => 4, :course_code => 'KJR-C2001', :name => 'Kiinteän aineen mekaniikan perusteet'},
        {:id => 13, :course_code => 'MS-A030x', :name => 'Differentiaali- ja integraalilaskenta 3'}
        #{:id => 6, :course_code => 'ENY-C2001', :name => 'Termodynamiikka ja lämmönsiirto'},
        #{:id => 12, :course_code => 'MS-A020x', :name => 'Differentiaali- ja integraalilaskenta 2'},
      ]
      @motivation_questions << {:id => 52, :course_code => 'KON-C3001', :name => 'Koneenrakennustekniikka A'} if chosen_course_ids.include?(52)
      # @motivation_questions << {:id => 49, :course_code => 'RAK-C3003', :name => 'Tietoyhdennetty rakentaminen'} if chosen_course_ids.include?(49)
      # @motivation_questions << {:id => 48, :course_code => 'KON-C3004', :name => 'Kone- ja rakennustekniikan laboratoriotyö'} if chosen_course_ids.include?(48)

    elsif chosen_competence_ids.include?(74) # RYM
      @major_name = 'Rakennetun ympäristön (RYM)'
      @major_id = 74
      
      @usefulness_questions = [
        {:id => 15, :course_code => 'MS-A050x', :name => 'Todennäköisyyslaskennan ja tilastotieteen peruskurssi'},
        {:id => 35, :course_code => 'PHYS-A3130', :name => 'Sähkömagnetismi (ENG)'},
        {:id => 98, :course_code => 'MAA-C2003', :name => 'Kiinteistötekniikan perusteet'},
        {:id => 12, :course_code => 'MS-A020x', :name => 'Differentiaali- ja integraalilaskenta 2'}
      ]
      @motivation_questions = [
        {:id => 15, :course_code => 'MS-A050x', :name => 'Todennäköisyyslaskennan ja tilastotieteen peruskurssi'},
        {:id => 35, :course_code => 'PHYS-A3130', :name => 'Sähkömagnetismi (ENG)'}
      ]
      @motivation_questions << {:id => 98, :course_code => 'MAA-C2003', :name => 'Kiinteistötekniikan perusteet'} if chosen_course_ids.include?(98)
      @motivation_questions << {:id => 12, :course_code => 'MS-A020x', :name => 'Differentiaali- ja integraalilaskenta 2'} if chosen_course_ids.include?(12)
      
    else
      # No major selected
      @major_name = ''
      @major_id = 0
      @usefulness_questions = []
      @motivation_questions = []
    end
    
    case @user.treatment
    when TREATMENT_GRAPH
      render :action => 'treatment'
    when TREATMENT_TRADITIONAL
      render :action => 'control'
    else
      redirect_to studyplan_competences_path()
    end
    
    log("survey view")
  end
  
  def create
    @answers = SurveyAnswer.new
    
    @answers.user = current_user
    @answers.studentnumber = current_user.studentnumber
    @answers.login = current_user.login
    @answers.survey_id = params[:survey_id]
    @answers.payload = (params[:questions] || {}).to_json
    @answers.save
    
    @user.treatment += 2
    @user.save(:validate => false)
    
    flash[:success] = 'Kiitos osallistumisestasi tutkimukseen!'
    redirect_to studyplan_competences_path()
    
    log("survey answer")
  end

end
