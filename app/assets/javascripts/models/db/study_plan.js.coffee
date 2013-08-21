class @StudyPlan extends DbObject
  # Nice and simple

  HASONE: []
  HASMANY: []

  DbObject::addSubClass(StudyPlan)

StudyPlan::HASONE.push([
  'User'
  'Curriculum'
  {'Period': 'firstPeriod'}
  {'Period': 'lastPeriod'}
])

StudyPlan::HASMANY.push([
  'Skill'
  'Competence'
  'AbstractCourse'
  'ScopedCourse'
  'PlanCourse'
  'CourseInstance'
  'Period'
])
