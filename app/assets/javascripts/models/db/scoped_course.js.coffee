class @ScopedCourse extends DbObject
  # Nice and simple

  DbObject::addSubClass(ScopedCourse)

ScopedCourse::ASSOCS.merge([
  ['abstractCourse', 'NotNull']
  'skills'
  ['prereqs', 'ScopedCourse']
])
