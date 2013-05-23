class StudyPlan < ActiveRecord::Base

  module RefCountExtension
    def add_or_increment_ref_count(course)
      StudyPlan.transaction do 
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id, 
                                               :scoped_course_id => course.id).first

        if not existing_entry.nil?
          # Increment reference counter
          existing_entry.competence_ref_count += 1
          existing_entry.save!
        else
          proxy_association.concat course
        end
      end
    end


    def remove_or_decrement_ref_count(course)
      StudyPlan.transaction do 
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id, 
                                               :scoped_course_id => course.id).first

        if not existing_entry.nil?
          # Decrement reference counter
          existing_entry.competence_ref_count -= 1
          if existing_entry.competence_ref_count == 0 && (not existing_entry.manually_added)
            # The last competence to which this course is a depedency has been removed
            existing_entry.destroy
            raise "Course could not be deleted" unless existing_entry.destroyed?
          else
            # Save the decremented counter
            existing_entry.save!
          end
        end
      end
    end
  end

  belongs_to :user

  has_many  :study_plan_courses,
            :dependent => :destroy

  has_many  :study_plan_competences,
            :dependent => :destroy

  has_many  :courses,
            :through => :study_plan_courses,
            :source => :scoped_course,
            :extend => RefCountExtension

  has_many  :passed_courses,
            :through => :study_plan_courses,
            :source => :scoped_course,
            :uniq => true,
            :conditions => "grade IS NOT NULL"

  has_many  :study_plan_manual_courses,
            :class_name => 'UserCourse',
            :dependent => :destroy,
            :conditions => { :manually_added => true }

  has_many  :manual_courses,
            :through => :study_plan_manual_courses,
            :source => :scoped_course,
            :uniq => true # manually added courses

  has_many :competences,
           :through => :study_plan_competences



 end
