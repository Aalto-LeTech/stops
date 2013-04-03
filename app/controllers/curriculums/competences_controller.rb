require 'eco'

class Curriculums::CompetencesController < CurriculumsController

  before_filter :load_competence, :except => [:index, :new, :create]

  authorize_resource :only => [:matrix]

  def load_competence
    @competence = Competence.find(params[:competence_id] || params[:id])

    #@profile = @competence.profile
    load_curriculum
  end
  
  def index
    load_curriculum
    # FIXME: there are no profiles any more.
    @competences = Competence.where(:profile_id => @curriculum.profile_ids)
                    .joins(:competence_descriptions)
                    .where(["competence_descriptions.locale = ?", I18n.locale])

    respond_to do |format|
      format.json { render :json => @competences.select(<<-SQL
          competence_nodes.id, 
          competence_descriptions.name AS translated_name
        SQL
      ).to_json(:methods => :strict_prereq_ids) } # :skill_ids
    end
  end

  # curriculums/1/competences/1
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @competence }

      format.json { render :json => @competence.to_json(
        :only => [:id],
        :include => {
            :skills => {
              :only => [:id],
              :include => {
                :skill_descriptions => {
                  :only => [:id, :locale, :description]
                },
                :skill_prereqs => {:only => [:prereq_id, :requirement]}
              }
            },
            :competence_descriptions => {
              :only => [:id, :locale, :description]
            }
        }
      )}
    end
  end

  # GET /competences/1/edit
  def edit
    authorize! :update, @curriculum
    
    # Add missing translations
    existing_locales = @competence.competence_descriptions.map {|description| description.locale}
    (REQUIRED_LOCALES - existing_locales).map do |locale|
      existing_locales = @competence.competence_descriptions << CompetenceDescription.new(:competence => @competence, :locale => locale, :name => '')
    end
    
  end


  def edit_prereqs
    @competence = Competence.find(params[:id])
    authorize! :update, @curriculum
    
    render :action => 'edit_prereqs', :layout => 'wide'
  end
  
  # PUT /competences/1
  # PUT /competences/1.xml
  def update
    authorize! :update, @curriculum
    
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
      @competence.competence_descriptions << CompetenceDescription.new(:competence => @competence, :locale => locale)
    end
  end
  
  def create
    load_curriculum
    @competence = Competence.new(params[:competence])
    authorize! :update, @curriculum
    
    respond_to do |format|
      if @competence.save
        format.html { redirect_to(edit_curriculum_path(@curriculum), :notice => 'Competence was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def contributors
    @courses = @competence.contributing_skills
  end

  def matrix
    return unless params[:prereqs]

    params[:prereqs].each do |prereq_id, row|
      row.each do |skill_id, value|
        new_requirement = false if value == '0'
        new_requirement = SUPPORTING_PREREQ if value == '1'
        new_requirement = STRICT_PREREQ if value == '2'

        # Read existing prereq
        existing_prereq = SkillPrereq.where(:skill_id => Integer(skill_id), :prereq_id => Integer(prereq_id)).first

        if new_requirement
          if existing_prereq
            # Update existing prereq
            existing_prereq.requirement = new_requirement
            existing_prereq.save
          else
            # Create new prereq
            SkillPrereq.create(:skill_id => Integer(skill_id), :prereq_id => Integer(prereq_id), :requirement => new_requirement)
          end
        else
          # Delete existing prereq
          existing_prereq.destroy
        end
      end
    end

    @competence.refresh_prereq_courses
  end

  def prereqs
    @competence = Competence.find(params[:id])

    render :action => 'prereqs', :layout => 'fullscreen'
  end
end


