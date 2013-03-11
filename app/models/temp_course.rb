class TempCourse < ActiveRecord::Base
  belongs_to :curriculum
  
  attr_accessible :alternatives, :assignments, :changing_topic, :code, :contact, :content, :credits, :department, :grading_scale, :grading_details, :graduate_course, :instructors, :language, :materials, :name_en, :name_fi, :name_sv, :other, :outcomes, :period, :prerequisites, :replaces
  
  
  def update_comments(hash)
    self.comments = hash.to_json
  end
  
  def comment(field)
    @comments = JSON.parse(read_attribute(:comments) || '{}') unless defined?(@comments)
    
    @comments[field]
  end
  
  def self.createScopedCourses
    
    TempCourse.find_each do |temp_course|
      abstract_course = AbstractCourse.find_by_code(temp_course.code)
      abstract_course = AbstractCourse.create(:code => temp_course.code) unless abstract_course
      
      scoped_course = ScopedCourse.create({
        :curriculum_id => temp_course.curriculum_id,
        :abstract_course_id => abstract_course.id,
        :course_code => temp_course.code,
        :credits => temp_course.credits,
        :contact => temp_course.contact,
        :language => temp_course.language,
        :instructors => temp_course.instructors,
        :graduate_course => temp_course.graduate_course,
        :changing_topic => temp_course.changing_topic,
        :period => temp_course.period,
        :comments => temp_course.comments
      })
      
      description_fi = CourseDescription.create({
        :scoped_course_id => scoped_course.id,
        :locale => 'fi',
        :name => temp_course.name_fi,
        :department => temp_course.department,
        :grading_scale => temp_course.grading_scale,
        :alternatives => temp_course.alternatives,
        :prerequisites => temp_course.prerequisites,
        :outcomes => temp_course.outcomes,
        :content => temp_course.content,
        :assignments => temp_course.assignments,
        :grading_details => temp_course.grading_details,
        :materials => temp_course.materials,
        :replaces => temp_course.replaces,
        :other => temp_course.other,
      })
      
      description_en = CourseDescription.create({
        :scoped_course_id => scoped_course.id,
        :locale => 'en',
        :name => temp_course.name_en
      })
      
      description_sv = CourseDescription.create({
        :scoped_course_id => scoped_course.id,
        :locale => 'sv',
        :name => temp_course.name_sv
      })
    end
    
    
  end
  
end
