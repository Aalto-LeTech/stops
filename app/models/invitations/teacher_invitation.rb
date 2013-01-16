class TeacherInvitation < Invitation
  belongs_to :target, :class_name => 'Curriculum'
  
  def accept(user)
    # TODO
#     course = Course.find(self.target_id)
#     course.teachers << user unless course.teachers.include?(user)
    
    role = CurriculumRole.new(:user => user, :target => self.target)
    role.role = 'teacher'
    role.save
    
    puts "INVITATION ACCEPTED"
    self.destroy
  end
end
