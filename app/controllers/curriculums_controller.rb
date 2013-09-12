class CurriculumsController < ApplicationController


  respond_to :html
  respond_to :json, :only => 'prereqs'

  layout 'views/curriculums/browser'

  #caches_page :prereqs


  def load_curriculum
    @curriculum = Curriculum.find(params[:curriculum_id])
  end


  # GET /curriculums
  # GET /curriculums.xml
  def index
    @curriculums = Curriculum.all(:order => 'start_year DESC')
    authorize! :read, Curriculum

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @curriculums }
    end
  end


  # GET /curriculums/1
  # GET /curriculums/1.xml
  def show
    load_curriculum_for_show_and_edit
    authorize! :read, @curriculum

    #@temp_courses = @curriculum.temp_courses
    @competences = Competence.where(:parent_competence_id => nil).includes([{:children => :localized_description}, :localized_description]).all

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/new
  # GET /curriculums/new.xml
  def new
    @curriculum = Curriculum.new
    authorize! :create, @curriculum

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @curriculum }
    end
  end

  # GET /curriculums/1/edit
  def edit
    load_curriculum_for_show_and_edit
    authorize! :update, @curriculum

    @competences = Competence.where(:parent_competence_id => nil).includes([{:children => :localized_description}, :localized_description]).all

    @courses = ScopedCourse
      .where(:curriculum_id => @curriculum.id)
      .joins(:course_descriptions)
      .where(:course_descriptions => { :locale => I18n.locale })
      .includes(:localized_description)
      .order('course_code, name')
  end


  # GET /curriculums/1/edit/import_csv
  def import_csv
    @curriculum = Curriculum.find(params[:id])
    authorize! :update, @curriculum
  end


  # POST /curriculums
  # POST /curriculums.xml
  def create
    @curriculum = Curriculum.new(params[:curriculum])
    authorize! :create, @curriculum

    @curriculum.admins << @current_user

    respond_to do |format|
      if @curriculum.save
        format.html { redirect_to(edit_curriculum_url(:id => @curriculum), :notice => 'Curriculum was successfully created.') }
        format.xml  { render :xml => @curriculum, :status => :created, :location => @curriculum }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @curriculum.errors, :status => :unprocessable_entity }
      end
    end
  end


  # PUT /curriculums/1
  # PUT /curriculums/1.xml
  def update
    @curriculum = Curriculum.find(params[:id])
    authorize! :update, @curriculum

    if params[:prereqs_csv]
      matrix = PrereqMatrix.new(params[:prereqs_csv], @curriculum, I18n.locale)
      matrix.process
      flash[:success] = "#{params[:prereqs_csv].original_filename} uploaded"
      redirect_to edit_import_csv_curriculum_path(@curriculum)
    elsif params[:courses_csv]
      @curriculum.import_courses params[:courses_csv].read
      flash[:success] = "#{params[:courses_csv].original_filename} uploaded"
      redirect_to edit_import_csv_curriculum_path(@curriculum)
    else
      respond_to do |format|
        if @curriculum.update_attributes(params[:curriculum])
          format.html { redirect_to(@curriculum, :notice => 'Curriculum was successfully updated.') }
          format.js { head :ok }
        else
          format.html { render :action => "edit", :notice => 'Saving unsuccessful, no data saved!'}
          format.js { head :internal_server_error }
        end
      end
    end
  end


  # DELETE /curriculums/1
  # DELETE /curriculums/1.xml
#   def destroy
#     @curriculum = Curriculum.find(params[:id])
#     authorize! :destroy, @curriculum
# 
#     @curriculum.destroy
# 
#     respond_to do |format|
#       format.html { redirect_to(curriculums_url) }
#       format.xml  { head :ok }
#     end
#   end


  # Get all strict prereqs of all courses
#   def prereqs
#     @curriculum = Curriculum.find(params[:id])
# 
#     prereqs = NodePrereq.where(:requirement => STRICT_PREREQ)
#                 .joins(<<-SQL
#                     INNER JOIN competence_nodes AS course ON course.id = node_prereqs_cache.competence_node_id
#                     INNER JOIN competence_nodes AS prereq ON prereq.id = node_prereqs_cache.prereq_id
#                   SQL
#                 ).where("course.curriculum_id = ?", @curriculum)
#                 .select(<<-SQL
#                     course.course_code AS course_code,
#                     prereq.course_code AS prereq_code,
#                     course.id AS course_id,
#                     prereq.id AS prereq_id
#                   SQL
#                 )
# 
#     respond_to do |format|
#       format.html { render :text => prereqs.to_json }
#       format.xml { render :xml => prereqs }
#       format.json { render :json => prereqs.to_json(:root => false) }
#     end
#   end


#   def graph
#     @curriculum = Curriculum.find(params[:id])
# 
#     prereqs = CoursePrereq.joins(:course)
#                 .where("competence_nodes.curriculum_id = ?", @curriculum)
#                 .where(:requirement => STRICT_PREREQ)
# 
#     render :action => 'graphviz', :locals => {:prereqs => prereqs}, :layout => false, :content_type => 'text/x-graphviz'
#   end


  def outcomes
    @curriculum = Curriculum.find(params[:id])
  end


  def search_skills
    curriculum_id = params[:id]
    node_ids = []
    if params[:q] && params[:q].size > 1
      excluded_node_id = false
      if params[:exclude]
        excluded_node_id = Integer(params[:exclude]) rescue false
      end

      # Search from skill
      skill_descriptions = SkillDescription.where(['name ILIKE ?', "%#{params[:q]}%"])
                               .joins(:skill)
                               .includes(:skill, :skill => :competence_node)
                               .select(:competence_node_id).uniq
      skill_descriptions.each do |skill_desc|
        node_id = skill_desc.skill.competence_node_id.to_i
        node_ids << node_id if not node_id == excluded_node_id
      end

      # Search from course names
      abstract_course_ids = CourseDescription.where(['name ILIKE ?', "%#{params[:q]}%"])
                               .select(:abstract_course_id).uniq.map do |description|
        description.abstract_course_id
      end
      
      # Search from course codes
      AbstractCourse.where(['code ILIKE ?', "%#{params[:q]}%"]).select(:id).uniq.each do |abstract_course|
        abstract_course_ids << abstract_course.id
      end
      
      ScopedCourse.where(:abstract_course_id => abstract_course_ids, :curriculum_id => curriculum_id).select(:id).find_each do |node|
        node_ids << node.id if not node.id == excluded_node_id
      end

      # Search from competence names
      nodes = CompetenceDescription.where(['name ILIKE ?', "%#{params[:q]}%"])
                               .joins(:competence)
                               .select(:competence_id).uniq
      nodes.each do |node|
        node_id = node.competence_id
        node_ids << node_id if not node_id == excluded_node_id
      end
    end

    nodes = CompetenceNode.includes(:skills => [:skill_descriptions, :skill_prereqs, :prereq_to]).find(node_ids)

    # Prepare CompetenceNode JSONs separately, because ScopedCourse and Competence need
    # different options for JSON generation.
    nodes_json = nodes.map do |node|
      if node.type == 'Competence'
        node.as_json(
          :only => [:id],
          :include => {
            :skills => {
                :only => [:id, :icon],
                :include => {
                  :skill_descriptions => {
                    :only => [:id, :locale, :name]
                  },
                  :skill_prereqs => {:only => [:prereq_id, :requirement]},
                  :prereq_to => {:only => [:id, :requirement, :icon]}
                }
            },
            :competence_descriptions => {
                :only => [:id, :locale, :name]
            }
          }
        )
      else
        # Must be a ScopedCourse
        node.as_json(
          :only => [:id, :course_code],
          :include => {
            :skills => {
                :only => [:id, :icon],
                :include => {
                  :skill_descriptions => {
                    :only => [:id, :locale, :name]
                  },
                  :skill_prereqs => {:only => [:prereq_id, :requirement]},
                  :prereq_to => {:only => [:id, :requirement, :icon]}
                }
            },
            :course_descriptions => {
                :only => [:id, :locale, :name]
            }
          }
        )
      end
    end

    respond_to do |format|
      format.json do
        render :json => nodes_json.to_json(:root => false)
      end
    end
  end


  def search_courses

    inqueryID    = params[:inqueryID]   or nil
    inquery      = params[:inquery]     or nil
    do_star      = params[:star]        or true
    max_matches  = params[:max_matches] or 20

    if inquery

      curriculum_id = params[:id]

      puts "=> Search: [%s (%s)]..." % [ inquery, inquery.encoding.name ]

      scoped_courses = ScopedCourse.search(
        inquery,
        star:         do_star,
        ranker:       :proximity_bm25,
        max_matches:  max_matches,
        per_page:     max_matches,
        with:         {curriculum_id: curriculum_id},
        sql:
        {
          :include =>
          [
            :abstract_course,
            :abstract_course => :localized_description,
            :skills => :localized_description,
            :prereqs =>
            [
              :abstract_course,
              :abstract_course => :localized_description
            ]
          ]
        }
      )

      scoped_course_ids = scoped_courses.map { |scoped_course| scoped_course.id }.uniq

      puts "Found %d entries: %s." % [ scoped_course_ids.length, scoped_course_ids ] # scoped_courses.total_entries

#      scoped_courses = ScopedCourse.find(
#        scoped_course_ids
#      ).all

      response_json = {
        status:     'ok',
        inqueryID:  inqueryID,
#        data:       as_hash(scoped_courses, serializer: ScopedCourseArraySerializer)
#        data:       as_hash(scoped_courses, each_serializer: ScopedCourseSerializer)
        data:       as_hash(
          scoped_courses,
          each_serializer: ScopedCourseSerializer
        )
      }.to_json

    else

      puts "ERROR: No query string given!"

      response_json = {
        status:     'error',
        inqueryID:  inqueryID
      }.to_json

    end

    #puts "=> Response:"
    #y JSON.parse(response_json)

    respond_to do |format|
      format.json do
        render :json => response_json
      end
    end
  end


  private

  # Loads curriculum object with necessary associations eagerly loaded
  def load_curriculum_for_show_and_edit
    @curriculum = Curriculum.includes(
      :courses,
      :courses => [:abstract_course, :periods, :localized_description, :strict_prereqs],
    ).find(params[:id])
  end

end
