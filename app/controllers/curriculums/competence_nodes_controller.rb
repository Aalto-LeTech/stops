class Curriculums::CompetenceNodesController < CurriculumsController

  def nodes_by_skill_ids
    nodes_json = nil
    
    if params[:ids]
      nodes = CompetenceNode.joins(:skills).where('skills.id' => params[:ids]).uniq

      nodes_json = nodes.map do |node|
        if node.type == 'Competence'
          node.as_json(
            :only => [:id],
            :include => [
              {:skills => {
                  :only => [:id],
                  :include => [
                    :skill_descriptions => {
                      :only => [:id, :locale, :description]
                    }
                  ]
              }},
              {:competence_descriptions => {
                  :only => [:id, :locale, :description]
              }}
            ]
          )
        else 
          # Must be a ScopedCourse
          node.as_json(
            :only => [:id, :course_code],
            :include => [
              {:skills => {
                  :only => [:id],
                  :include => [
                    :skill_descriptions => {
                      :only => [:id, :locale, :description]
                    }
                  ]
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
      format.json { render :json => nodes_json }
    end
  end


end