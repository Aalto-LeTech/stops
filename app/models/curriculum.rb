class Curriculum < ActiveRecord::Base


  validates_presence_of :start_year
  validates_presence_of :end_year


  # Competences
  has_many :competences,
           :dependent   => :destroy


  # Courses
  has_many :courses,
           :class_name  => 'ScopedCourse',
           :dependent   => :destroy,
           :order       => 'course_code'

  has_many :temp_courses,
           :dependent   => :destroy,
           :order       => 'code, created_at'


  # Roles
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

      #puts "Proceeding to a prereq of #{course.course_code}"
      self.add_course(start, prereq, courses, cycles, stack)
    end

    stack.pop

    #puts "Returning from #{course.course_code}"

  end


  # Returns all strict prereqs of all courses
  # returns a hash where keys are scoped_course_ids and values are arrays of scoped_course_ids
  def prereqs_array
    courses = ScopedCourse.where(:curriculum_id => self.id)

    result = {}
    courses.each do |course|
      result[course.course_code] = course.strict_prereq_ids
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


  def import_courses(input)
    lines = input.lines
    #line_count = lines.size
    #line_counter = 0
    begin
      while line = lines.next.strip
        next if line.blank?

        if line.include?('-') && line.size < 15
          code = line
          name_en = lines.next.strip
          name_fi = lines.next.strip
          name_sv = lines.next.strip
          credits = lines.next.strip.to_i
        else
          code = ''
          name_fi = line
          name_en = ''
          name_sv = ''
          credits = 5
        end

        # Find or create abstract course
        if code.blank?
          abstract_course_id = nil
        else
          abstract_course = AbstractCourse.find_by_code(code) || AbstractCourse.create(:code => code)
          abstract_course_id = abstract_course.id
        end

        # Create course
        course = ScopedCourse.create(:curriculum_id => self.id, :abstract_course_id => abstract_course_id, :credits => credits, :course_code => code)
        description_fi = CourseDescription.create(:scoped_course_id => course.id, :locale => 'fi', :name => name_fi)
        description_en = CourseDescription.create(:scoped_course_id => course.id, :locale => 'en', :name => name_en)
        description_sv = CourseDescription.create(:scoped_course_id => course.id, :locale => 'sv', :name => name_sv)
        puts "Code: #{code}, Name(en): #{name_en}, Name(fi): #{name_fi}, Credits: #{credits}"

        # Create skills
        while line = lines.next.strip
          if line == 'Osaamistavoitteet:'

            while line = lines.next.strip
              break if line.blank? # || line.include?(':')

              if line[0] == '-'
                text = line[2..-1]
              else
                text = line
              end

              skill = Skill.create(:competence_node_id => course.id)
              SkillDescription.create(:skill_id => skill.id, :locale => 'fi', :description => text)
              SkillDescription.create(:skill_id => skill.id, :locale => 'en', :description => text)
              SkillDescription.create(:skill_id => skill.id, :locale => 'sv', :description => text)
              puts "  #{text}"
            end
          end

          break if line.blank?
        end


      end
    rescue StopIteration => e
    end
  end

end
