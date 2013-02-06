class Curriculum < ActiveRecord::Base

  validates_presence_of :start_year
  validates_presence_of :end_year

  has_many :profiles, 
           :dependent   => :destroy

  has_many :courses, 
           :class_name  => 'ScopedCourse', 
           :dependent   => :destroy, 
           :order       => 'course_code'
  
  has_many :temp_courses, 
           :dependent   => :destroy, 
           :order       => 'code, created_at'

  has_many :teacher_roles, 
           :class_name  => 'CurriculumRole', 
           :conditions  => {:type => 'CurriculumRole', :role => 'teacher'}, 
           :foreign_key => 'target_id', 
           :include     => :user

  has_many :teachers, :through => :teacher_roles, :source => :user
  
  has_many :admin_roles, 
           :class_name  => 'CurriculumRole', 
           :conditions  => {:type => 'CurriculumRole', :role => 'admin'}, 
           :foreign_key => 'target_id', 
           :include     => :user

  has_many :admins, :through => :admin_roles, :source => :user

  #has_and_belongs_to_many :admins, :class_name => 'User', :join_table => 'curriculum_roles'

  # Returns a human-readable representation, e.g. "2010" or "2010-2011"
#   def name
#     return '' if self.new_record?
#
#     return read_attribute(:name) unless read_attribute(:name).blank?
#
#     if self.end_year > self.start_year
#       return "#{self.start_year} - #{self.end_year}"
#     else
#       return self.start_year
#     end
#   end

  def has_admin?(user)
    return false unless user
    self.admins.exists?(:id => user.id)
  end
  
  def has_teacher?(user)
    return false unless user
    self.teachers.exists?(:id => user.id)
  end

  # Returns all courses and their prereqs that form this profile
  def detect_cycles
    cycles = Array.new

    self.courses.each do |course|
      courses = Hash.new
      stack = Array.new
      add_course(course, course, courses, cycles, stack) unless courses.has_key?(course.id)
    end

    return cycles
  end

  # Adds a course and its prereqs recursively to the given courses collection. If a course belongs to a prereq cycle, it is added to the cycles collection.
  def add_course(start, course, courses, cycles, stack)
    if courses.has_key?(course.id)
      return
    end

    courses[course.id] = course

    stack.push(course)

    # Add pereqs of this course to the list
    course.strict_prereqs.each do |prereq|
      if prereq == start
        cycles << stack.clone
        stack.pop
        return
      end

      #puts "Proceeding to a prereq of #{course.code}"
      self.add_course(start, prereq, courses, cycles, stack)
    end

    stack.pop

    #puts "Returning from #{course.code}"

  end

  # Returns all strict prereqs of all courses
  # returns a hash where keys are scoped_course_ids and values are arrays of scoped_course_ids
  def prereqs_array
    courses = ScopedCourse.where(:curriculum_id => self.id)

    result = {}
    courses.each do |course|
      result[course.code] = course.strict_prereq_ids
    end

    return result
  end
  
  # Creates TeacherInvitations and mails them to users
  # addresses: array of email addresses
  # subject: subject of the email (string)
  # content: body of the email (string). LINK will be replaced with the invitation URL
  def self.invite_teachers(curriculum_id, addresses, subject, content)
    addresses.each do |address|
      next unless address.include?('@')
      
      invitation = TeacherInvitation.create(:target_id => curriculum_id, :email => address.strip, :expires_at => Time.now() + 2.weeks)
      InvitationMailer.teacher_invitation(invitation, subject, content).deliver
    end    
  end
end
