class StudyPlan < ActiveRecord::Base

  module RefCountExtension
    def add_or_increment_ref_count(*args)
      options = args.extract_options!
      course, = *args # Last comma forces nil value when args is empty

      course_id = options[:id] || course.id

      StudyPlan.transaction do 
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id, 
                                                 :scoped_course_id => course_id).first

        if not existing_entry.nil?
          # Increment reference counter
          existing_entry.competence_ref_count += 1
          existing_entry.save!
        else 
          course = ScopedCourse.find(course_id) if not course
          proxy_association.concat course
        end
      end
    end


    def remove_or_decrement_ref_count(*args)
      options = args.extract_options!
      course, = *args # Last comma forces nil value when args is empty

      course_id = options[:id] || course.id

      StudyPlan.transaction do 
        study_plan = proxy_association.owner
        plan_id = study_plan.id

        existing_entry = StudyPlanCourse.where(:study_plan_id => plan_id, 
                                                 :scoped_course_id => course_id).first

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

  belongs_to :curriculum

  has_many  :study_plan_courses,
            :dependent => :destroy

  has_many  :study_plan_competences,
            :dependent => :destroy

  has_many  :courses,
            :through => :study_plan_courses,
            :source => :scoped_course,
            :extend => RefCountExtension,
            :dependent => :destroy

  has_many  :study_plan_manual_courses,
            :class_name => 'StudyPlanCourse',
            :dependent => :destroy,
            :conditions => { :manually_added => true }

  has_many  :manual_courses,
            :through => :study_plan_manual_courses,
            :source => :scoped_course,
            :dependent => :destroy,
            :uniq => true

  has_many :competences,
           :through => :study_plan_competences,
           :dependent => :destroy

  
  def as_json(options={})
    super(options.merge({
      :only => [:curriculum_id],
      :include => {
        :study_plan_courses => {
          :only => [:scoped_course_id, :period_id]
        }
      },
    }))
  end

  def add_competence(competence)
    # Dont't do anything if the study plan already has this competence
    return if has_competence?(competence)

    competences << competence

    # FIXME: This breaks if prerequisites include Competences
    
    # Calculate union of existing and new courses, without duplicates
    courses_array = self.courses | competence.courses_recursive

    self.courses = courses_array
  end

  # Removes the given competence and courses that are needed by it. Courses that are still needed by the remaining competences, are not removed. Also, manually added courses are not reomved.
  def remove_competence(competence)
    # Remove competence
    competences.delete(competence)

    self.courses = needed_courses(self.competences).to_a
  end

  def has_competence?(competence)
    competences.include? competence
  end

  # Returns a list of courses than can be deleted if the given competence is dropped from the study plan
  def deletable_courses(competence)
    # Make an array of competences that the user has after deleting the given competence
    remaining_competences = competences.clone
    remaining_competences.delete(competence)
    puts "#{competences.size} / #{remaining_competences.size}"

    # Make a list of courses that are needed by the remaining competences
    needed_courses = needed_courses(remaining_competences)

    courses.to_set - needed_courses
  end

  # Returns a set of courses that are needed by the given competences
  # competences: a collection of competence objects
  def needed_courses(competences)
    # Make a list of courses that are needed by remaining profiles
    needed_courses = Set.new
    competences.each do |competence|
      needed_courses.merge(competence.courses_recursive)
    end

    # Add manually added courses to the list
    needed_courses.merge(manual_courses)
  end

  def passed?(course)
    passed_courses.include?(course.id)
  end

end
