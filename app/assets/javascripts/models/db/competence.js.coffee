class @Competence extends DbObject
  # Nice and simple

  HASONE: []
  HASMANY: []

  DbObject::addSubClass(Competence)

Competence::HASMANY.push({'ScopedCourse': 'strictPrereq'})
