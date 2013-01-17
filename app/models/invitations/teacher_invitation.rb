class TeacherInvitation < Invitation
  belongs_to :target, :class_name => 'Curriculum'
  attr_accessible :target
  
  def accept(user)
    unless CurriculumRole.exists?(:user_id => user.id, :target_id => self.target.id)
      role = CurriculumRole.new(:user => user, :target => self.target)
      role.role = 'teacher'
      role.save
    end
    
    self.destroy
  end
end
