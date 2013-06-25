class @Course

  constructor: (data) ->
    this.loadJson(data || {})
    
    @x = ko.observable(0)
    @y = ko.observable(0)
    
#     this.instances      = {};         # Available course instances FIXME C20130619
#     this.periods        = [];         # Periods on which this course is arranged
#     this.prereqs        = {};         # Prerequisite courses. courseCode => course object
#     this.prereqTo       = {};         # Courses for which this course is a prereq. courseCode => course object
#     this.prereqPaths    = [];         # Raphael paths to prerequirement courses
#     this.period         = false;      # Period 
#     this.courseInstance = false;      # Selected courseinstance
#     this.slot           = false;      # Slot number that this course occupies
#     this.length         = 1;
#     this.locked         = false;      # Is the course immovable?
#     this.unschedulable          = false;      # true if period allocation algorithm cannot find suitable period
#     this.prereqsUnsatisfiableIn = {};         # Set of periods where prereqs of the course cannot be satisfied. From period.id => period */
#     this.changed        = true;
# 
#     this.id           = element.data('id');    # Database id of the UserCourse
#     this.course_code  = element.data('code');
#     this.name         = element.data('name');
#     this.credits      = parseFloat(element.data('credits'));
#     this.passed       = element.data('passed') == 'true';
# 
#     element.click(courseClicked);
# 
#     element.draggable({
#       containment: 'parent',
#       distance:     5,
#       start:        courseDragStarted,
#       drag:         courseBeingDragged,
#       stop:         courseDragStopped,
#       revert:       "false"
#     });
# 
#     # Click handler registration must come after initializing draggable or otherwise 
#     # clicks will not be prevented correctly after drags. */
#     element.click(courseClicked);

  loadJson: (data) ->
    @id = data['id']
    @course_code = data['course_code'] || ''
    @name = data['localized_name'] || ''

# 
#   getCode: () ->
#     return this.course_code;
#   };
# 
#   getLength: () ->
#     return this.length;
#   };
# 
#   getCredits: () ->
#     return this.credits;
#   };
# 
#   isPassed: () ->
#     return this.passed;
#   };
# 
#   setSlot: (slot) {
#     this.slot = slot;
#     this.element.css('left', slot * 115);
#   };
# 
#   getSlot: () ->
#     return this.slot;
#   };
# 
#   getPrereqs: () ->
#     return this.prereqs;
#   };
# 
#   # Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
#   addPrereq: (other) ->
#     this.prereqs[other.course_code] = other;
#     other.prereqTo[this.course_code] = this;
#   };
# 
#   # Adds an instance of this course to the given period. 
#   addCourseInstance: (courseInstance) ->
#     period = courseInstance.getPeriod();
#     this.instances[period.getId()] = courseInstance;
#     this.periods.push(period);
#   };
# 
#   # Moves this course to the given period
#   setPeriod: (period) ->
#     # Remove course from previous period. Note: length must not be updated before freeing the old slots.
#     if (this.period) {
#       this.period.removeCourse(this);
#     }
# 
#     # Update length
#     this.courseInstance = this.instances[period.getId()];
#     if (this.courseInstance) {
#       this.length = this.courseInstance.length;
#     } else {
#       this.length = 1;
#     }
# 
#     # Add course to the new period
#     this.period = period;
#     period.addCourse(this, false);
# 
#     # Move the div
#     period_div_pos = period.element.position();
#     #course.css('left', period_div_pos.left + freeSlot * 100);
#     this.element.css('top', period_div_pos.top + 3);
#     this.element.css('height', this.length * 42 + (this.length - 1) * 15);
#     this.element.removeClass("hide");
# 
#     console.log("setPeriod: called on course: " + this.code + " " + this.name);
# 
#     # Update possible prerequirement graph paths of the current course and any of the paths of its postrequirement courses.
#     this.updatePrereqPaths();
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
#   # (i.e., there were no available periods with course instances late enough
#   # to satisfy prerequirements).
#   markUnschedulable: () ->
#     if (!this.locked) {
#       # Remove period
#       if (this.period) {
#         this.period.removeCourse(this);
#         this.courseInstance = false;
#         this.period = false;
#       }
# 
#       this.unschedulable = true;
# 
#       console.log("markUnschedulable: Marked unschedulable course " + this.code + " " + this.name);
# 
#       # Remove course element from view
#       this.element.addClass("hide");
#     }
#   };
# 
#   getPeriod: (period) ->
#     return this.period;
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
#   # Moves forward all courses that require this course
#   satisfyPostreqs: () ->
#     # Quit recursion if this course is part of an unsolvable chain
#     if (!this.period) {
#       # Mark the rest of the postrequirements as unschedulable since we weren't able to schedule the current course.
#       this.markPostreqsUnschedulable();
#       return;
#     }
# 
#     # Determine to which period postrerequirements should be postponed */
#     targetPeriod;
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
#     
#     # Postpone postreqs that are earlier than this
#     for (array_index in this.prereqTo) {
#       other = this.prereqTo[array_index];
#       
#       if (!targetPeriod || this.period.laterOrEqual(other.period)) {
#         if (!other.locked) other.postponeTo(targetPeriod);
#         other.satisfyPostreqs();
#       }
#     }
#   };
# 
#   # Moves this course to the first available period starting from the given period.
#   postponeTo: (period) ->
# 
#     this.setPeriod(period);
# 
#     if (!this.unschedulable) {
#       while (period) {
#         if (period.courseAvailable(this)) {
#           this.setPeriod(period);
#           return;
#         }
# 
#         period = period.getNextPeriod();
#       }
#       
#       # No period could be found.
#       this.markPostreqsUnschedulable(); # Also marks period as false
#       console.log("Unschedulable: " + this.code + " " + this.name + ": Could not postpone to wanted period!");
#     }
# 
#   };
# 
#   # Moves this to the given period or the closest possible earlier period
#   advanceTo: (period) ->
#     while (period) {
#       if (period.courseAvailable(this)) {
#         this.setPeriod(period);
#         return;
#       }
# 
#       period = period.getPreviousPeriodUntilCurrent();
#     }
# 
#     # No period could be found.
#     this.clearPeriodAndHide();
#   };
# 
#   # Moves the course forward after its prereqs (those that have been located on a period).
#   # If no prereqs are found, course remains on the current period.
#   postponeAfterPrereqs: () ->
#     # Only move if the course has not been locked into its current period
#     if (!this.locked) {
#       # Find the latest of the prereqs
#       latest = false;
#       for (array_index in this.prereqs) {
#         course = this.prereqs[array_index];
#         period = course.getPeriod();
#         
#         if (period && (!latest || period.laterThan(latest))) {
#           latest = period;
#         }
#       }
#       
#       if (latest) {
#         targetPeriod  = latest.getNextPeriod(),
#             currentPeriod = latest.getCurrentPeriod();
#         if (targetPeriod && targetPeriod.earlierOrEqual(currentPeriod)) {
#           # We must make sure that courses are scheduled only after the current ongoing period! */
#           targetPeriod = currentPeriod.getNextPeriod();
#         }
#         this.postponeTo(targetPeriod);
#       }
#     }
#   };
# 
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
#   drawPrereqPaths: () ->
#     preCourse; 
#     for (preCourse in this.prereqs) {
#       if (!this.prereqs.hasOwnProperty(preCourse)) {
#         continue;
#       }
#       preCourse = this.prereqs[preCourse];
# 
#       if (!preCourse.period) {
#         # The course is hidden and no prerequirement graph edge should be drawn!
#         continue;
#       }
# 
#       prereqElem = $(planView.escapeSelector('course-' + preCourse.code));
# 
#       newPath = planView.paper.path(Course.calcPathString(this.element, prereqElem));
#       this.prereqPaths.push({ path: newPath, course: preCourse });
#     }
#   };
# 
#   updatePrereqPaths: () ->
#     for (i = 0; i < this.prereqPaths.length; i++) {
#       node          = this.prereqPaths[i],
#           path          = node.path,
#           prereqCourse  = node.course,
#           $prereqElem   = $(planView.escapeSelector('course-' + prereqCourse.code));
#       path.attr({ path: Course.calcPathString(this.element, $prereqElem) });
#     }
#   };
# 
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
# 
#   # Course event listeners
#   courseClicked: () ->
#     course = $(this).data('object');
# 
#     # Clear prerequirement graphs
#     course.clearPrereqPaths();
# 
#     # Reset hilights
#     $('.course').removeClass('prereq-of').removeClass('prereq-to').removeClass('selected');
#     $('.period').removeClass('receiver').removeClass("warning").removeClass("old-period");
#     
#     # Hilight selected course
#     $(this).addClass('selected');
# 
#     # computing an appropriate prereqs string
#     prereqsz = 0;
#     prereqs_string, course_name_list_string = '';
#     for (array_index in course.prereqs) {
#       prereq_course = course.prereqs[array_index]
#       if (prereq_course) {
#         prereqsz++;
#         course_name_list_string += prereq_course.name + ', '
#       }
#     }
#     if (prereqsz == 0) {
#       prereqs_string = '-';
#     } else {
#       prereqs_string = String(prereqsz) + course_name_list_string;
#     }
# 
#     # Show short course details on the controls pane
#     $courseDesc = $('#course-desc-block');
#     $("#course-code").text(course.course_code); 
#     $("#course-name").text(course.name);
#     $("#course-points").text(course.credits);
#     
#     prereqs = $.map course.prereqs, (course) -> return course
#     
#     $("#course-prereqs-list").html(JST['templates/_schedule_prerequirement_courses'](
#       {
#         prereqs:            prereqs,
#         no_prereqs_message: planView.translations.no_prereqs_message
#       }
#     ));
# 
#     $courseDesc.removeClass("hidden"); # TODO animate
#     $courseLockInput = $("#schedule-course-lock-input");
#     $courseLockInput.removeAttr("disabled");
#     $courseLockInput.prop("checked", course.locked);
# 
#     
#     course.checkPrereqSatisfiability();
# 
#     # Hilight prereqs
#     for (array_index in course.prereqs) {
#       course.prereqs[array_index].element.addClass('prereq-of');
#     }
# 
#     # Hilight courses for which this is a prereq
#     for (array_index in course.prereqTo) {
#       course.prereqTo[array_index].element.addClass('prereq-to');
#     }
# 
#     # Hilight the periods that have this course
#     for (array_index in course.periods) {
#       period = course.periods[array_index];
#       if (period.laterOrEqual(planView.currentPeriod)) {
#         period.element.addClass("receiver");
# 
#         if (period.id in course.prereqsUnsatisfiableIn) {
#           period.element.addClass("warning");
#         }
#       } else {
#         period.element.addClass("old-period");
#       }
#     }
# 
# 
#     # Draw requirement graphs for selected course */
#     if (planView.settings.drawPrerequirementGraphs) {
#       course.drawPrereqPaths();
#     }
#   }
# 
# 
#   courseDragStarted: (event, ui) ->
#     $element = ui.helper;
# 
#     if (!$element.hasClass("selected")) {
#       # The course is being dragged before having been clicked
#       # and thus isn't selected yet. Call to clickhandler fixes that.
#       # Notice that we must call the clickhandler in the correct context! */
#       courseClicked.call(ui.helper[0]);
#     }
# 
#     # Reset hilights
#     $('.period').removeClass('receiver');
# 
#     # Dragging started, reset drop detection
#     ui.helper.data('dropped', false);
# 
#     # Hilight the periods that have this course
#     periods = $element.data('object').periods;
# 
#     for (array_index in periods) {
#       periods[array_index].element.addClass("receiver");
#     }
# 
#     course = $element.data("object");
#   }
# 
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
#   calcPathString: (courseNode, prereqNode) ->
#     fX, fY, tX, tY, coursePos, prereqPos;
#     coursePos = courseNode.position();
#     prereqPos = prereqNode.position();
#     
#     if (!coursePos || !prereqPos) {
#       return '';
#     }
#     
#     fX = coursePos.left + courseNode.outerWidth(true) / 2.0;
#     fY = coursePos.top;
#     tX = prereqPos.left + prereqNode.outerWidth(true) / 2.0;
#     tY = prereqPos.top + prereqNode.outerHeight(false) + prereqNode.margin().top;
# 
#     return "M" + fX + "," + fY + "T" + tX + "," + tY;
