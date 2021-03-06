class Curriculums::CompetencesController < ApplicationController

  before_filter :load_competence, :only => [:edit, :edit_prereqs, :update, :graph, :courselist]
  
  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id] || params[:id])
  end
  
  def load_competence
    @competence = Competence.find(params[:competence_id] || params[:id])
    load_curriculum
  end

  def index
    load_curriculum
    @competences = Competence.where(:curriculum_id => @curriculum.id)
                    .joins(:competence_descriptions)
                    .where(["competence_descriptions.locale = ?", I18n.locale])

    respond_to do |format|
      format.json { render :json => @competences.select(<<-SQL
          competence_nodes.id,
          competence_descriptions.name AS translated_name
        SQL
      ).to_json(:methods => :strict_prereq_ids, :root => true) } # :skill_ids
    end
  end

  # curriculums/1/competences/1
  def show
    load_curriculum

    respond_to do |format|
      format.html {
        load_plan
    
        @competence = Competence.includes(:localized_description, {:skills => :localized_description}).find(params[:id])
        @chosen_competence_ids = @study_plan.competence_ids.to_set
        
        # Log
        @client_session_id = SecureRandom.hex(3)
        render :action => 'show', :layout => 'leftnav'
        log("view_competence #{@competence.id} (#{@client_session_id})")
      }

      format.json {
        @competence = Competence.includes(:skills => [:skill_descriptions, :skill_prereqs, :prereq_to]).find(params[:competence_id] || params[:id])
        render :json => @competence.to_json(
          :only => [:id],
          :include => {
              :skills => {
                :only => [:id, :icon],
                :include => {
                  :skill_descriptions => {
                    :only => [:id, :locale, :name]
                  },
                  :skill_prereqs => {:only => [:prereq_id, :requirement]}
                }
              },
              :competence_descriptions => {
                :only => [:id, :locale, :name]
              }
          },
          :root => true 
        )
      }
    end
  end

  # GET /competences/1/edit
  def edit
    authorize! :update, @competence

    # Add missing translations
    existing_locales = @competence.competence_descriptions.map {|description| description.locale}
    (REQUIRED_LOCALES - existing_locales).map do |locale|
      existing_locales = @competence.competence_descriptions << CompetenceDescription.new(:competence => @competence, :locale => locale, :name => '', :term_id => @curriculum.term_id)
    end

    render :action => 'edit', :layout => 'views/curriculums/container'
  end


  def edit_prereqs
    #@competence = Competence.find(params[:id])
    @competence_node = @competence
    authorize! :update, @competence

    @hide_help = cookies[:hide_edit_competence_prereqs_help] == 't' ? true : false

    @competence_node_url = curriculum_competence_path(:curriculum_id => @curriculum, :competence_id => @competence)

    render :action => 'edit_prereqs', :layout => 'views/curriculums/container'
  end

  # PUT /competences/1
  # PUT /competences/1.xml
  def update
    authorize! :update, @competence
    @curriculum.save  # Expire cache

    respond_to do |format|
      if @competence.update_attributes(params[:competence])
        format.html { redirect_to edit_curriculum_path(@curriculum) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def new
    load_curriculum
    @competence = Competence.new(:curriculum => @curriculum)

    authorize! :update, @curriculum

    REQUIRED_LOCALES.each do |locale|
      @competence.competence_descriptions << CompetenceDescription.new(:competence => @competence, :locale => locale, :term_id => @curriculum.term_id)
    end
    
    render :action => 'new', :layout => 'views/curriculums/browser'
  end

  def create
    load_curriculum
    authorize! :update, @curriculum
    @curriculum.save  # Expire cache
    
    @competence = Competence.new(params[:competence])
    @competence.term = @curriculum.term

    respond_to do |format|
      if @competence.save
        format.html { redirect_to(edit_curriculum_path(@curriculum), :notice => 'Competence was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def graph
    #@competence = Competence.find(params[:id])

    render :action => 'graph', :layout => 'views/curriculums/container'
  end
  
  def courselist
    #@competence = Competence.find(params[:id])
    
    render :action => 'courselist', :layout => 'views/curriculums/container'
  end
end
