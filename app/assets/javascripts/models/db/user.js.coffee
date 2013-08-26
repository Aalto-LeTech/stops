class @User extends DbObject
  # Nice and simple

  DbObject::addSubClass(User)

User::ASSOCS.merge([
  ['studyPlan', 'NotNull']
])
