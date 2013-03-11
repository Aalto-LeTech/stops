function GraphLevel(level_number) {
  this.number = level_number;
  this.courses = [];
  this.courseMargin = 20;
  this.height = 0;
}

GraphLevel.prototype.addCourse = function(course) {
  this.courses.push(course);
}

GraphLevel.prototype.getCourses = function(course) {
  return this.courses;
}

GraphLevel.prototype.getWidth = function(course) {
  return this.courses.length;
}

GraphLevel.prototype.updateHeight = function(course) {
  this.height = 0;

  for (var course_index in this.courses) {
    var course = this.courses[course_index];
    this.height += course.getElement().height() + this.courseMargin;
  }

  return this.height;
}

GraphLevel.prototype.setYindicesBackwards = function() {
  // Set each course to the barycenter of the forward neighbors
  for (var course_index in this.courses) {
    var course = this.courses[course_index];
    var visibleNeighbors = 0;

    // Calculate average of the y coordinates of the forward neighbor
    var y = 0.0;
    for (var neighbor_index in course.prereqTo) {
      var neighbor = course.prereqTo[neighbor_index];
      if (neighbor.visible) {
        y += neighbor.y;
        visibleNeighbors++;
      }
    }

    if (course.prereqTo.length > 0) {
      y /= visibleNeighbors;
    } else {
      y = this.height / 2.0;
    }
  }

  this.distributeCoursesEvenly();
}

GraphLevel.prototype.setYindicesForward = function() {
  // Set each course to the barycenter of the backward neighbors
  for (var course_index in this.courses) {
    var course = this.courses[course_index];
    var visibleNeighbors = 0;

    //console.log("Positioning " + course.name);

    // Calculate average of the y coordinates of the backward neighbor
    var y = 0.0;
    for (var neighbor_index in course.prereqs) {
      var neighbor = course.prereqs[neighbor_index];
      if (neighbor.visible) {
        y += neighbor.y;
        visibleNeighbors++;
      }
    }
    //console.log("Sum = " + y);

    if (course.prereqTo.length > 0) {
      y /= visibleNeighbors;
    } else {
      y = this.height / 2.0;
    }

    //console.log("Average = " + y);
  }

  this.distributeCoursesEvenly();
}

GraphLevel.prototype.distributeCoursesEvenly = function() {
  // Sort courses by Y
  this.courses.sort(function(a,b){b.y - a.y});

  // Distribute evenly
  //var step = (this.maxHeight - this.height) / (this.courses.length - 1)
  var y = this.maxHeight / 2.0 - this.height / 2;
  //console.log("maxHeight = " + this.maxHeight);
  for (var course_index in this.courses) {
    var course = this.courses[course_index]
    course.y = y;
    y += course.getElement().height() + this.courseMargin;
  }
}


function GraphCourse(id, code, name) {
  this.element = false;
  this.id = id;
  this.course_code = code;
  this.name = name;
  this.isCompetence = false;

  this.level = 0;
  this.x = 0;
  this.y = 0;

  this.skills = [];
  this.prereqs = [];
  this.prereqTo = [];

  this.visible = false;
  this.visibleNeighborsForward = 0;
  this.visited = false;

//   this.visited = false;
//   this.prereqs = {};           // Prerequisite courses. courseCode => course object
//   this.prereqTo = {};          // Courses for which this course is a prereq. courseCode => course object
//   this.prereqsCount = 0;
//   this.prereqToCount = 0;

  this.x = 0;
  this.y = 0;

};

GraphCourse.prototype.addSkill = function(skill) {
  this.skills.push(skill);
}

GraphCourse.prototype.addPrereq = function(course) {
  this.prereqs.push(course);
  course.prereqTo.push(this);
}

/**
 * Returns a div.
 **/
GraphCourse.prototype.getElement = function(view) {
  if (this.element) {
    return this.element;
  }

  var cssClass = this.isCompetence ? ' competence' : ''
  var div = $('<div class="course' + cssClass + '"><h1>' + this.course_code + ' ' + this.name + '</h1></div>');
  div.click($.proxy(this.click, this));
  this.view = view;

  var ul = $('<ul />');
  div.append(ul);

  for (var array_index in this.skills) {
    var skill = this.skills[array_index];
    skill.view = view;
    var li = $('<li>' + skill.description + '</li>');
    skill.element = li;
    ul.append(li);
    li.click($.proxy(skill.click, skill));
  }

  this.element = div;

  return div;
}

GraphCourse.prototype.setCompetence = function(value) {
  this.isCompetence = value;
}

GraphCourse.prototype.setPosition = function(x, y) {
  this.x = x;
  this.y = y;
  this.element.offset({ left: this.x, top: this.y });
}

GraphCourse.prototype.updatePosition = function() {
  this.element.offset({ left: this.x, top: this.y });
}

GraphCourse.prototype.click = function() {
  // Reset hilights and SVG
  this.view.resetHilights();

  for (var skill_index in this.skills) {
    var skill = this.skills[skill_index];

    skill.dfsBackward(true);
    skill.visited = false;
    skill.dfsForward(true);
  }

  this.view.resetVisitedSkills();
}
