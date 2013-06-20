class FreeCourseSchedulingFromInstances < ActiveRecord::Migration
  def up
    # objective:
    #   free course scheduling from course instances
    #     previously scoped courses course scheduling 
    # according to my understanding we do not need to change
    #   abstract_course
    # but we need to change
    #   study_plan_course

    remove_column :study_plan_courses, :course_instance_id

  end

  def down

    add_column :study_plan_courses, :course_instance_id

  end
end
