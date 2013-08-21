class @CourseModel extends ModelObject
  # Nice and simple


  BYSCID: {}
  BYACID: {}
  BYPCID: {}


  create: (dbCourse) ->
    if dbCourse instanceof PlanCourse
      courseModel = @BYPCID[dbCourse.id]
    else if dbCourse instanceof ScopedCourse
      courseModel = @BYSCID[dbCourse.id]

    if not courseModel
      courseModel = new CourseModel(dbCourse)

    return courseModel


  constructor: (dbCourse) ->
    super()

    @lg("Modeling #{dbCourse}...")

    @abstractCourse = @scopedCourse = @planCourse = undefined

    if dbCourse instanceof ScopedCourse
      @scopedCourse = dbCourse
      @abstractCourse = @scopedCourse?.abstractCourse
    else if dbCourse instanceof PlanCourse
      @planCourse   = dbCourse
      @abstractCourse = dbCourse.abstractCourse
      @scopedCourse = dbCourse.scopedCourse



    # Mapping the object

    if not @abstractCourse
      dbg.lgW("Created a Course with no access to an abstract course!")
    else
      @BYACID[@abstractCourse.id] = this

    if not @scopedCourse
      dbg.lgW("Created a Course with no access to a scoped course!")
    else
      @BYSCID[@scopedCourse.id] = this

    if @planCourse
      @BYPCID[@planCourse.id] = this

    @lg("Modeling from #{@scopedCourse}")


    # Binding attributes

    @code = ko.computed =>
      return @abstractCourse.code

    @name = ko.computed =>
      return @abstractCourse.localizedName

    @credits = ko.computed =>
      return @scopedCourse.credits

    @grade = ko.computed =>
      return @planCourse?.grade || ''

    @period = ko.computed =>
      return @planCourse?.period

    @periodName = ko.computed =>
      return @period()?.localizedName

    @skills = ko.computed =>
      return @scopedCourse.skills || []

    @prereqs = ko.computed =>
      return @scopedCourse.prereqs || []

    @path = ko.computed =>
      return @scopedCourse.studyplanPath

    @isPassed = ko.computed =>
      return @grade() > 0

    @isIncluded = ko.computed =>
      return this in @VIEWMODEL.PLAN.included()

    @isAdded = ko.computed =>
      return this in @VIEWMODEL.PLAN.added()

    @isRemoved = ko.computed =>
      return this in @VIEWMODEL.PLAN.removed()

    @isScheduled = ko.computed =>
      return @period()?

    @tooltip = ko.computed =>
      if @isAdded()
        tooltip = "#{@I18N.is_added_to_the_plan}"
      else if @isRemoved()
        tooltip = "#{@I18N.is_removed_from_the_plan}"
      else if @isIncluded()
        tooltip = "#{@I18N.is_included_in_the_plan}"
      else
        tooltip = "#{@I18N.is_not_included_in_the_plan}"
      if @isScheduled()
        if @isPassed()
          tooltip += " #{@I18N.and_passed_with_grade} #{@grade} #{@I18N.in_period} #{@period.name}"
        else
          tooltip += " #{@I18N.and_scheduled_to_period} #{@period.name}"
      else if @isPassed()
        if @isIncluded()
          tooltip += " #{@I18N.and_passed_with_grade} #{@grade}#{@I18N.but_not_scheduled}"
        else
          tooltip += " #{@I18N.and_passed_with_grade}"
      tooltip += "."
      return tooltip

    @isSelected  = ko.observable(false)


  includeToPlan: ->
    @lg("course::includeToPlan()...")
    @VIEWMODEL.PLAN.add(this)


  removeFromPlan: ->
    @lg("course::removeFromPlan()...")
    @VIEWMODEL.PLAN.remove(this)


  toggleInclusion: ->
    @lg("course::toggleInclusion()...")
    return @removeFromPlan() if @isIncluded()
    return @includeToPlan()


  # Renders the object into a string for debugging purposes
  toString: ->
    return "#{super()}:{#{@code()}}"
