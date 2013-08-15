class Curriculums::CompetenceNodesController < CurriculumsController

  def nodes_by_skill_ids
    nodes_json = []
    
    if params[:ids]
      nodes = CompetenceNode.joins(:skills).where('skills.id' => params[:ids]).includes(:skills => [:skill_descriptions, :prereq_to]).uniq

      nodes_json = nodes.map do |node|
        if node.type == 'Competence'
          node.as_json(
            :only => [:id],
            :include => [
              {:skills => {
                  :only => [:id, :icon],
                  :include => {
                    :skill_descriptions => {
                      :only => [:id, :locale, :description]
                    },
                    :prereq_to => {:only => [:id, :requirement, :icon]}
                  }
              }},
              {:competence_descriptions => {
                  :only => [:id, :locale, :name, :description]
              }}
            ]
          )
        else 
          # Must be a ScopedCourse
          node.as_json(
            :only => [:id, :course_code],
            :include => [
              {:skills => {
                  :only => [:id, :icon],
                  :include => {
                    :skill_descriptions => {
                      :only => [:id, :locale, :description]
                    },
                    :prereq_to => {:only => [:id, :requirement, :icon]}
                  }
              }},
              {:course_descriptions => {
                  :only => [:id, :locale, :name]
              }}
            ]
          )
        end
      end
    end

    respond_to do |format|
      format.json { render :json => nodes_json, :root => false }
    end
  end


end