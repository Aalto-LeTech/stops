class @Competence extends DbObject
  # Nice and simple

  CLASSNAME: 'Competence'

  DbObject::addSubClass(Competence)

Competence::ASSOCS.merge([
  ['strictPrereqs', 'ScopedCourse']
])
