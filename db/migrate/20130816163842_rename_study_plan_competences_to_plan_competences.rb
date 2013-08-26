class RenameStudyPlanCompetencesToPlanCompetences < ActiveRecord::Migration
  def up
    rename_table :study_plan_competences, :plan_competences
    # cli
    #   mfsreplace -d app/ script/ -r "studyplancompetence" "plancompetence" -r "study_plan_competence" "plan_competence" -r "study plan competence" "plan competence" -r "StudyPlanCompetence" "PlanCompetence" -r "studyPlanCompetence" "planCompetence"
  end

  def down
    rename_table :plan_competences, :study_plan_competences
  end
end
