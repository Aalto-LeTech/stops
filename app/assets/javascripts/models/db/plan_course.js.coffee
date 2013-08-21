class @PlanCourse extends DbObject
  # Nice and simple

  HASONE: []
  HASMANY: []

  DbObject::addSubClass(PlanCourse)

PlanCourse::HASONE.push([
  {'AbstractCourse': {notNull: true}}
  {'ScopedCourse': {notNull: true}}
  'CourseInstance'
  'Period'
])
