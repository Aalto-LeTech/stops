class @User extends DbObject
  # Nice and simple

  CLASSNAME: 'User'

  DbObject::addSubClass(User)

User::ASSOCS.merge([
  ['studyPlan', 'NotNull']
])
