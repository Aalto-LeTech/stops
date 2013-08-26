class @Competence extends DbObject
  # Nice and simple

  DbObject::addSubClass(Competence)

Competence::ASSOCS.merge([
  ['strictPrereqs', 'ScopedCourse']
])
