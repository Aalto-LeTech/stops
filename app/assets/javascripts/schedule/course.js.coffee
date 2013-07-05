class @Course

  constructor: (data) ->
    this.loadJson(data || {})
    
    @hilightSelected = ko.observable(false)
    @hilightPrereq = ko.observable(false)
    @hilightPrereqTo = ko.observable(false)
    @orderWarning = ko.observable(false)
    
    @position = ko.observable({x: 0, y: 0, height: 1})
    
    @instancesByPeriodId = {}           # Available course instances. periodId => CourseInstance
    @instanceCount  = 0
    @periods        = []                # Periods on which this course is arranged
    @prereqs        = {}                # Prerequisite courses. courseId => Course
    @prereqTo       = {}                # Courses for which this course is a prereq. courseId => Course object
    @prereqPaths    = []                # Raphael paths to prerequirement courses
    @period         = undefined         # Scheduled Period 
    @courseInstance = undefined         # Scheduled CourseInstance
    @slot           = undefined         # Slot number that this course occupies
    @length         = 1                 # Length in periods
    @locked         = false             # Is the course immovable?
    @unschedulable  = false             # true if period allocation algorithm cannot find suitable period
    @changed        = false             # Tracks whether changes need to be saved


  loadJson: (data) ->
    @id = data['id']
    @course_code = data['course_code'] || ''
    @name = data['localized_name'] || ''
    @credits = data['credits'] || 0
    @grade = undefined  # TODO
  
  toJson: ->
    json = { scoped_course_id: @id }
    json['period_id'] = @period.id if @period?
    return json
  

  # Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
  addPrereq: (other) ->
    @prereqs[other.id] = other
    other.prereqTo[@id] = this


  # Adds an instance of this course to the given period. 
  addCourseInstance: (courseInstance) ->
    period = courseInstance.period
    @periods.push(period)
    @instancesByPeriodId[period.id] = courseInstance
    @instanceCount++


  # Moves the course to the given period, to a free slot. Does not update DOM.
  # Updates @period and @slot
  setPeriod: (period) ->
    # Remove course from previous period. Note: length must not be updated before freeing the old slots.
    @period.removeCourse(this) if (@period)

    # Update length
    @courseInstance = @instancesByPeriodId[period.id]
    
    if (@courseInstance)
      @length = @courseInstance.length
    else
      @length = 1

    # Add course to the new period
    @period = period
    @slot = period.addCourse(this)
    

  # Updates the DOM elements to match model
  updatePosition: ->
    # Move the div
    pos = @position()
    pos.x = @slot * (PlanView.COURSE_WIDTH + PlanView.COURSE_MARGIN_X) + PlanView.COURSE_MARGIN_X
    pos.y = @period.position().y + PlanView.COURSE_MARGIN_Y
    pos.height = @length * PlanView.PERIOD_HEIGHT - 2 * (PlanView.COURSE_MARGIN_Y + PlanView.COURSE_PADDING_Y)
    @position.valueHasMutated()
    
    # Update possible prerequirement graph paths of the current course and any of the paths of its postrequirement courses.
    this.updatePrereqPaths()

  # Update warnings
  updateWarnings: ->
    warning = false
    
    for courseId,other of @prereqs
      warning = true if other.period? && @period? && other.period.laterOrEqual(@period)
      #other.updateWarnings()
    
    for courseId,other of @prereqTo
      warning = true if other.period? && @period? && other.period.earlierOrEqual(@period)
      #other.updateWarnings()
    
    @orderWarning(warning)
    
  

#     $.each this.prereqTo, (key, postReqCourse) ->
#       postReqCourse.updatePrereqPaths();
# 
# 
#   clearPeriodAndHide: () ->
#     if (this.period) {
#       this.period.removeCourse(this);
#     }
#     this.period = false;
# 
#     this.clearPrereqPaths();
#     this.element.addClass("hide");
#   };
# 
#   # Mark the course as unschedulable by the automatic scheduling algorithm
#   # (i.e., there were no available periods with course instances late enough to satisfy prerequirements)
  markUnschedulable: () ->
    @unschedulable = true
#     if (!this.locked) {
#       # Remove period
#       if (this.period) {
#         this.period.removeCourse(this);
#         this.courseInstance = false;
#         this.period = false;
#       }
# 
#       
# 
#       console.log("markUnschedulable: Marked unschedulable course " + this.code + " " + this.name);
# 
#       # Remove course element from view
#       this.element.addClass("hide");
#     }
#   };
# 
#   checkPrereqSatisfiabilityInPeriod: (period) ->
#     positions = {},               # Simulated current periods of courses
#         coursesToBeChecked = [this];
# 
#     # The course must be in the period that we want to check
#     positions[this.id] = period;
# 
#     _getPeriodOfCourse = (course) ->
#       if (course.id in positions)
#         return positions[course.id]
#       else
#         positions[course.id] = course.period
#         return course.period
# 
# 
#     # Simulate satisfyPrereqs()
#     while (coursesToBeChecked.length != 0) {
#       course = coursesToBeChecked.pop(),
#           prereq_code,
#           periodOfCourse = _getPeriodOfCourse(course);
# 
#       console.log("POP: Popped " + course.code + " " + course.name + " from stack");
# 
#       if (!periodOfCourse) {
#         # Prereqs cannot be satisfied */
#         this.prereqsUnsatisfiableIn[period.id] = period;
#         return;
#       }
# 
#       for (prereq_code in this.prereqs) {
#         # Get current simulated period values */
#         prereq         = this.prereqs[prereq_code],
#             periodOfPrereq = _getPeriodOfCourse(prereq);
# 
#         console.log("PREREQ: Handling prereq course " + prereq.code + " " + prereq.name);
# 
#         if (periodOfCourse.earlierThan(periodOfPrereq)) {
#           # advanceTo(period) simulation */
#           targetPeriod = periodOfCourse.getPreviousPeriod();
#           while (targetPeriod) {
#             if (targetPeriod.courseAvailable(course)) {
#               break;
#             }
# 
#             targetPeriod = targetPeriod.getPreviousPeriod();
#           }
# 
#           positions[prereq.id] = targetPeriod;
#           if (!targetPeriod) console.log("PREREQ COURSE UNSCHEDULABLE: No target period could be found!");
# 
#           coursesToBeChecked.push(prereq);
#           console.log("PUSH: Pushed " + prereq.code + " " + prereq.name + " into stack");
#         }
#       }
#     }
# 
#   };
# 
#   checkPrereqSatisfiability: () ->
#     course = this;
#     $.each this.periods, (i, period) ->
#       course.checkPrereqSatisfiabilityInPeriod(period) if (period.earlierThan(course.period))
# 
# 
#   isSchedulableInPeriod: (period) ->
#     if (period.id in this.prereqsUnsatisfiableIn)
#       return false
#     else
#       return true
# 
# 
#   # Moves all prereqs before this course.
#   satisfyPrereqs: () ->
#     # Quit recursion if this course is part of an unsolvable chain
#     if (!this.period) {
#       return;
#     }
# 
#     # Move prereqs before this course
#     for (array_index in this.prereqs) {
#       other = this.prereqs[array_index];
# 
#       if (this.period.earlierThan(other.period)) {
#         other.advanceTo(this.period.getPreviousPeriodUntilCurrent());
#         other.satisfyPrereqs();
#       }
#     }
#   };
# 
  # Recursively moves forward all courses that require this course
  satisfyPostreqs: () ->
    # Quit recursion if this course is part of an unsolvable chain
    unless @period?
#       # Mark the rest of the postrequirements as unschedulable since we weren't able to schedule the current course.
#       this.markPostreqsUnschedulable();
      this.markUnshedulable()
      return


    # Determine to which period postrerequirements should be postponed */
#     if (this.locked) {
#       # Since the current course is locked, the course might be before
#       # its prerequirements, so we need to find out the latest period of
#       # the set of the current course and its prerequirements. */
#       latest = this.getPeriod();
#       for (array_index in this.prereqs) {
#         course = this.prereqs[array_index];
#         period = course.getPeriod();
#         
#         if (period && (!latest || period.laterThan(latest))) {
#           latest = period;
#         }
#       }
# 
#       targetPeriod = latest.getNextPeriod();
#     } else {
#       # Move postrequirements right after the current course */
#       targetPeriod = this.getPeriod().getNextPeriod();
#     }
    
    targetPeriod = @period.nextPeriod
    unless targetPeriod?
      # TODO: mark postreqs unschedulable
      return
    
    # Postpone postreqs that are earlier than this
    for id,other of @prereqTo
      if !other.period? || this.period.laterOrEqual(other.period)
      #if (!targetPeriod || this.period.laterOrEqual(other.period)) {
        console.log "#{other.name} depends on #{@name}. Postponing to #{targetPeriod}."
        other.postponeTo(targetPeriod) unless other.locked
        other.satisfyPostreqs()


  # Moves this course to the first available period starting from the given period.
  postponeTo: (requestedPeriod) ->
    #this.setPeriod(period);

    # If no instances are known for this course, put it on the requested period
    if (this.instanceCount < 1)
      this.setPeriod(requestedPeriod)
      this.markUnschedulable()
      return

    #if (!this.unschedulable) {
    period = requestedPeriod
    while (period)
      if @instancesByPeriodId[period.id]
        this.setPeriod(period)
        return
      
      period = period.getNextPeriod()
    
    # No period could be found. Put it on the requested period
    this.setPeriod(requestedPeriod)
    this.markUnschedulable()
    
    #  this.markPostreqsUnschedulable(); # Also marks period as false
    #  console.log("Unschedulable: " + this.code + " " + this.name + ": Could not postpone to wanted period!");
    #}

  # Moves this to the given period or the closest possible earlier period
  advanceTo: (requestedPeriod) ->
    period = requestedPeriod
    while (period)
      if @instancesByPeriodId[period.id]
        this.setPeriod(period)
        return

      period = period.getPreviousPeriodUntilCurrent()
    
    # No period could be found. Put it on the requested period
    this.setPeriod(requestedPeriod)
    # TODO: add warning
    
    # No period could be found.
    #this.clearPeriodAndHide();


  # Moves the course forward after its prereqs (those that have been put on a period).
  # If no prereqs are found, course remains unmodified.
  postponeAfterPrereqs: () ->
    # Only move if the course has not been locked into its current period
    return if this.locked
  
    # Find the latest prereq
    latestPeriod = false
    for id,prereq of this.prereqs
      period = prereq.getPeriod()
      latestPeriod = period if period? && (!latestPeriod || period.laterThan(latestPeriod))

    return unless latestPeriod

    # Put course on the next period after latest prereq
    targetPeriod = latestPeriod.getNextPeriod() || latestPeriod
    
    # Don't schedule courses before current period
    if targetPeriod.earlierThan(Period::currentPeriod)
      targetPeriod = Period::currentPeriod
    
    this.postponeTo(targetPeriod)
  
  
#   # Mark all (except locked courses) postrequirements and their postrequirements as unschedulable. */
#   markPostreqsUnschedulable: () ->
#     to_be_processed = $.map this.prereqTo, (course) ->
#       return course;
#     
#     while(to_be_processed.length > 0) {
#       postreq = to_be_processed.pop();
#       postreq.markUnschedulable();
#       $.each postreq.prereqTo, (key, course) ->
#         to_be_processed.push(course);
# 
# 
  drawPrereqPaths: () ->
    for id,other of @prereqs
      continue unless other.period

      pathString = Course.calcPathString(this.position(), other.position())
      newPath = PlanView::paper.path(pathString)
      @prereqPaths.push({ path: newPath, course: other })



  updatePrereqPaths: () ->
    for node in @prereqPaths
      path  = node.path
      other = node.course
      path.attr({ path: Course.calcPathString(this.position(), other.position()) })


#   clearPrereqPaths: ->
#     selectedCourseElem = $("#plan .selected");
#     if (selectedCourseElem.length !== 0)
#       selectedCourse = selectedCourseElem.data('object'); 
#       for (i = 0; i < selectedCourse.prereqPaths.length; i++) {
#         selectedCourse.prereqPaths[i].path.remove();
#       }
# 
#       selectedCourse.prereqPaths = [];
# 
# 
#   lock: () ->
#     this.locked = true;
#     this.element.draggable("disable");
#     this.element.addClass("locked");
#     # Show lock icon on course div
#     $img = $("img.course-locked", "#cloneable-imgs").clone();
#     this.element.append($img);
# 
#   unlock: () ->
#     this.locked = false;
#     this.element.draggable("enable");
#     this.element.removeClass("locked");
#     # Hide lock icon from course div */
#     this.element.find("img.course-locked").detach();
# 
#   courseBeingDragged: (event, ui) ->
#     # Move prerequirement graphs
#     elem = ui.helper,
#         course = elem.data('object');
# 
#     course.updatePrereqPaths();
#   }
# 
#   courseDragStopped: (event, ui) ->  # FIXME???
#     if (!ui.helper.data('dropped'))
#       # Animate draggable back to its original position
#       ui.helper.animate(ui.originalPosition, { 
#         duration: 500,
#         step: (now, fx) ->
#           $courseElem = $(this),
#             course = $courseElem.data('object');
# 
#           # Update graphs too
#           course.updatePrereqPaths();
#       })
# 
# 
#   # Calculates SVG path string between course node element and a prerequirement
#   # element.
  calcPathString: (coursePosition, otherPosition) ->
    fX = coursePos.left + courseNode.outerWidth(true) / 2.0;
    fY = coursePos.top;
    tX = prereqPos.left + prereqNode.outerWidth(true) / 2.0;
    tY = prereqPos.top + prereqNode.outerHeight(false) + prereqNode.margin().top;

    return "M" + fX + "," + fY + "T" + tX + "," + tY;