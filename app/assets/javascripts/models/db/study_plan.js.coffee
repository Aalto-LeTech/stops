class @StudyPlan extends DbObject
  # Nice and simple

  CLASSNAME: 'StudyPlan'

  DbObject::addSubClass(StudyPlan)

StudyPlan::ASSOCS.merge([
  'user'
  'curriculum'
  'firstPeriod'
  'lastPeriod'
  'skills'
  'competences'
  'abstractCourses'
  'scopedCourses'
  'planCourses'
  'courseInstances'
  'periods'
])
