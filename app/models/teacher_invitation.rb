class TeacherInvitation < Invitation
  belongs_to :target, :class_name => 'Curriculum'
  attr_accessible :target, :target_id
  
  def accept(user)
    unless CurriculumRole.exists?(:user_id => user.id, :target_id => self.target.id)
      role = CurriculumRole.new(:user => user, :target => self.target)
      role.role = 'teacher'
      role.save
    end
    
    user.staff = true
    user.treatment = nil
    user.save(:validate => false)
    
    self.destroy
  end
end
