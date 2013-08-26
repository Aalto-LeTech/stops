class @PlanCourse extends DbObject
  # Nice and simple

  DbObject::addSubClass(PlanCourse)

PlanCourse::ASSOCS.merge([
  ['abstractCourse', 'NotNull']
  ['scopedCourse', 'NotNull']
  'courseInstance'
  'period'
])
