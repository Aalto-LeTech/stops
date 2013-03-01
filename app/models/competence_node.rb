class CompetenceNode < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :curriculum

  has_many :skills, :autosave => true, :dependent => :destroy

end
