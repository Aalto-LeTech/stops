class CompetenceNode < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :curriculum

  belongs_to :parent_competence,
             :class_name => 'CompetenceNode'

  has_many :contained_competences,
           :foreign_key => :parent_competence_id,
           :class_name  => 'Competence'

  has_many :skills, :autosave => true, :dependent => :destroy

  validate :validates_parent_competence_not_a_self_reference


  private 

  def validates_parent_competence_not_a_self_reference
    if self.parent_competence_id == self.id
      errors[:base] << "CompetenceNode cannot refer to itself through 'parent_competence'."
    end
  end

end
