
class CurriculumRole < Role

  belongs_to :target, :class_name => 'Curriculum'

end
