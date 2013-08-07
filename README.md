Sprints
=======

Sprint 17.7 - 30.7
------------------

- [x] new: major restructuring
  add study_plan_course.length (however get length returns scoped_course.length if nil)
  add study_plan_course.custom
  add study_plan.first_period_id and last_period_id
  add study_plan_courses.abstract_course_id
  add course_description.abstract_course_id
  rm  course_description.scoped_course_id and do related modification
- [x] fix: clean redundant and deprecated code (eg. profile related code), refactor
- [x] new: add study_plan.periods function and remove user.relevant_periods
- [x] fix: rewrite course_description accessing related code
- [x] new: refactor PlanView
- [x] fix: highlight custom courses
- [x] fix: fix the unselecting issue
- [x] fix: switch from knockout 2.2.1 to 2.3.0
- [x] fix: PlanView save logic (eg. permit the removal of user courses)
- [x] new: indication of unpassed courses scheduled into the past (misscheduled)
- [x] fix: fix and test the schedule related logic
- [x] new: when a competence is selected, display a progress bar
- [x] new: added smart tooltips for period credits, competence progress and course divs
- [x] fix: don't show the grade field for courses scheduled to the future and autoremove their grades
- [x] new: show the editable course fields only when hovering on the well
- [x] new: make length customizable
- [x] new: add extenders and customized binders to make everything work smoothly
- [x] fix: fixed a few broken things in the new student workflow
- [x] fix: fixed and fine tuned many things while testing PlanView (verry time consuming)
- [ ] fix: make the plan scroll and the top and side elements remain visible when scrolling the schedule grid
- [ ] fix: redesign the "autoscroll to current period" feature
- [ ] new: add intro description into competence view in case no coms chosen
- [ ] new: test the basic scheduler work flow with some scenarios with "fresh users"
- [ ] new: add a
- [ ] new: studyplan/courses/index: course searching (use Sphinx, see skillEditor)
- [ ] new: allow NULL for course_description.scoped_course_id
- [ ] new: studyplan/courses/index: allow creation of custom study_plan_courses (name, )
- [ ] new: test the work flow with some scenarios
- [ ] something else
- [ ] new: textual description of a course's state (eg: "The course is scheduled into the past!", "The current chronology of scheduled courses does not satisfy course prerequirement relations.")
- [ ] new: modifying course lenght

If excess time
- [ ] fix the course_description.scoped_course_id problem
- [ ] add a "fix course ordering" button into the PlanView
- [ ] show the fit of available competences to the currently selected/completed studies
- [ ] offer the possibility of creating alternate study_plans and even comparing them effectively


Sprint 10.7 - 17.7.
-------------------

- [x] replace the i18n hack with the other one
- [x] fix the "extent" input field size and add tooltips
- [x] autoscroll to show some past & the current period while focusing on the near future
- [x] starterd using rvm and added .ruby-version .ruby-gemset to the repo
- [x] redirect to schedule instead of student dashboard
- [x] dump dashboard
- [x] new: highlight period total credits when the scheduled period is over or underbooked
- [x] starterd using rbenv and dumped rvm & .ruby-gemset
- [x] new: highlight passed courses
- [x] new: highlight courses based on whether they are instance-bound or not
- [x] fix: fixed some update errors and cleaned other odd stuff, added comments
- [x] new: rewrite of the plan save method series: error resistance, efficiency, logging and support for user_course addition
- [x] fix: made scheduler keep a record of which courses were actually altered
- [x] fix: optimized plan parsing by avoiding repeated repositioning of courses
- [x] fix: make course.length a ko observable
- [x] fix: redesign & write period's total credit count management
- [x] new: better guessing for a course object's length in periods when it has no course instances at that period
- [x] new: make the view model know which parts of the JSON sent for saving was accepted by the server
- [x] fix: redesign sidebar layout
- [x] new: add a prereq list
- [x] new: when a period is selected, display information about it
- [x] new: when nothing is selected, competences are shown at the bar
- [x] new: when a competence is selected, related courses are highlighted


O4 koulutus tuutoreille 27.8. 16:00
===================================
Paikka: K215


w #c09853 #a47e3c
e #b94a48 #953b39
i #3a87ad #2d6987
s #468847 #356635
