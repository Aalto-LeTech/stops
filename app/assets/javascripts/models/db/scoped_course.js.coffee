class @ScopedCourse extends DbObject
  # Nice and simple

  HASONE: []
  HASMANY: []

  DbObject::addSubClass(ScopedCourse)

ScopedCourse::HASONE.push({'AbstractCourse': {notNull: true}})

ScopedCourse::HASMANY.push([
  'Skill'
  {'ScopedCourse': 'prereq'}
])
