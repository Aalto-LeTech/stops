class @PlanCourse extends @DbObject
  # Nice and simple

  CLASSNAME: 'PlanCourse'

  DbObject::addSubClass(PlanCourse)

PlanCourse::ASSOCS.merge([
  ['abstractCourse', 'NotNull']
  ['scopedCourse', 'NotNull']
  'courseInstance'
  'period'
])
