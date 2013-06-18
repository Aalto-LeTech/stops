module CompetencesHelper

  def get_chosen_competences
    @chosen_competences = @user.study_plan.competence_ids.inject(Set.new) do |set, id|
      set << id
    end
  end

end
