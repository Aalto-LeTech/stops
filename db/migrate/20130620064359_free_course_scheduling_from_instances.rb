class FreeCourseSchedulingFromInstances < ActiveRecord::Migration
  def up
    # objective:
    #   free course scheduling from course instances
    #     previously scoped courses course scheduling 

    remove_column :study_plan_courses, :course_instance_id

  end

  def down

    add_column :study_plan_courses, :course_instance_id

  end
end
