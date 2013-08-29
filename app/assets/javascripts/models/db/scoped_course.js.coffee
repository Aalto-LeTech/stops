class @ScopedCourse extends DbObject
  # Nice and simple

  CLASSNAME: 'ScopedCourse'

  DbObject::addSubClass(ScopedCourse)

ScopedCourse::ASSOCS.merge([
  ['abstractCourse', 'NotNull']
  'skills'
  ['prereqs', 'ScopedCourse']
])
