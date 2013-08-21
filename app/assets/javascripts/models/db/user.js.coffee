class @User extends DbObject
  # Nice and simple

  HASONE: []
  HASMANY: []

  DbObject::addSubClass(User)

User::HASONE.push({'StudyPlan': {notNull: true}})
