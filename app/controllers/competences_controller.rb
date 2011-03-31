class CompetencesController < ApplicationController

  # GET /competences/1
  # GET /competences/1.xml
  def show
    @competence = Competence.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @competence }
    end
  end

  # GET /competences/new
  # GET /competences/new.xml
  def new
    @profile = Profile.find(params[:profile_id])
    @competence = Competence.new
    @competence.competence_descriptions << CompetenceDescription.new(:locale => I18n.locale)

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.xml  { render :xml => @competence }
    end
  end

  # GET /competences/1/edit
  def edit
    @competence = Competence.find(params[:id])
  end

  # POST /competences
  # POST /competences.xml
  def create
    @profile = Profile.find(params[:profile_id])
    
    @competence = Competence.new(params[:competence])
    @competence.profile = @profile

    respond_to do |format|
      if @competence.save
        format.html { redirect_to(@competence, :notice => 'Competence was successfully created.') }
        format.js { }
        format.xml  { render :xml => @competence, :status => :created, :location => @competence }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @competence.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /competences/1
  # PUT /competences/1.xml
  def update
    @competence = Competence.find(params[:id])

    respond_to do |format|
      if @competence.update_attributes(params[:competence])
        format.html { redirect_to(@competence, :notice => 'Competence was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @competence.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /competences/1
  # DELETE /competences/1.xml
  def destroy
    @competence = Competence.find(params[:id])
    @competence.destroy

    respond_to do |format|
      format.html { redirect_to(competences_url) }
      format.xml  { head :ok }
    end
  end
end
