# Competence profile, e.g. Steel structures
class Profile < ActiveRecord::Base

  belongs_to :curriculum
  
  has_many :profile_descriptions, :dependent => :destroy
  has_many :competences, :dependent => :destroy   # e.g. levels 1, 2, 3
  
  accepts_nested_attributes_for :profile_descriptions
  
  def name(locale)
    description = profile_descriptions.where(:profile_id => self.id, :locale => locale.to_s).first
    description ? description.name : ''
  end
  
  def description(locale)
    description = profile_descriptions.where(:profile_id => self.id, :locale => locale.to_s).first
    description ? description.description : ''
  end

  
  # Creates competence levels I-III
  def create_default_competences
    level_names = ["","I","II","III"]
    
    for i in 1..3 do
      competence = Competence.create(:profile => self, :level => i)
      CompetenceDescription.create(:competence => competence, :locale => 'fi', :name => level_names[i], :description => '')
      CompetenceDescription.create(:competence => competence, :locale => 'en', :name => level_names[i], :description => '')
    end
  end
  
end
