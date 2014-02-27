class Curriculum < ActiveRecord::Base

  validates_presence_of :start_year
  validates_presence_of :end_year

  belongs_to :term
  
  # Competences
  has_many :competences,
           :dependent   => :destroy

  # Courses
  has_many :courses,
           :class_name  => 'ScopedCourse',
           :dependent   => :destroy,
           :order       => 'course_code'

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
        course = ScopedCourse.create(:curriculum_id => self.id, :abstract_course_id => abstract_course_id, :credits => credits, :course_code => code, :term_id => self.term_id)
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

              skill = Skill.create(:competence_node_id => course.id, :term_id => self.term_id)
              SkillDescription.create(:skill_id => skill.id, :locale => 'fi', :name => text)
              SkillDescription.create(:skill_id => skill.id, :locale => 'en', :name => text)
              SkillDescription.create(:skill_id => skill.id, :locale => 'sv', :name => text)
              puts "  #{text}"
            end
          end

          break if line.blank?
        end


      end
    rescue StopIteration => e
    end
  end

  def duplicate(term)
    new_node_ids = {}   # old_node_id => copy_node_id
    new_skill_ids = {}  # old_node_id => copy_node_id
    skills = []
    skill_ids = []
    
    # Duplicate the Curriculum
    new_curriculum = self.dup
    new_curriculum.name += ' (copy)'
    new_curriculum.term = term
    new_curriculum.save
    
    # Duplicate ScopedCourses
    ScopedCourse.where(:curriculum_id => self.id).find_each do |node|
      node_copy = node.dup
      node_copy.curriculum = new_curriculum
      node_copy.locked = false
      node_copy.term = term
      node_copy.save
      new_node_ids[node.id] = node_copy.id
      
      skills.concat(node.skills)
      skill_ids.concat(node.skill_ids)
    end
    
    # Duplicate Competences
    Competence.where(:curriculum_id => self.id).order('parent_competence_id DESC').find_each do |node|
      # NOTE: order by parent_competence_id so that nested competences are handled last and the new parent_competence_ids are known
      node_copy = node.dup(:include => :competence_descriptions)
      node_copy.curriculum = new_curriculum
      node_copy.parent_competence_id = new_node_ids[node.parent_competence_id] if node.parent_competence_id
      node_copy.locked = false
      node_copy.term = term
      node_copy.save
      new_node_ids[node.id] = node_copy.id
      
      skills.concat(node.skills)
      skill_ids.concat(node.skill_ids)
    end

    # Duplicate all Skills
    skills.each do |skill|
      skill_copy = skill.dup(:include => :skill_descriptions)
      skill_copy.skill_descriptions.each { |skill_description| skill_description.term = term }
      skill_copy.competence_node_id = new_node_ids[skill_copy.competence_node_id]
      skill_copy.term = term
      skill_copy.save
      new_skill_ids[skill.id] = skill_copy.id
    end
    
    # Duplicate SkillPrereqs
    SkillPrereq.where(:skill_id => skill_ids).find_each do |skill_prereq|
      prereq_copy = skill_prereq.dup
      prereq_copy.skill_id = new_skill_ids[prereq_copy.skill_id]
      prereq_copy.prereq_id = new_skill_ids[prereq_copy.prereq_id]
      prereq_copy.term = term
      prereq_copy.save
    end
    
    # Duplicate Roles
    CurriculumRole.where(:target_id => self.id).find_each do |role|
      role_copy = role.dup
      role_copy.target_id = new_curriculum.id
      role_copy.save
    end
    
    return new_curriculum
  end
end
