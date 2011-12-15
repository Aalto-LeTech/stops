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

    console.log("Positioning " + course.name);

    // Calculate average of the y coordinates of the backward neighbor
    var y = 0.0;
    for (var neighbor_index in course.prereqs) {
      var neighbor = course.prereqs[neighbor_index];
      if (neighbor.visible) {
        y += neighbor.y;
        visibleNeighbors++;
      }
    }
    console.log("Sum = " + y);

    if (course.prereqTo.length > 0) {
      y /= visibleNeighbors;
    } else {
      y = this.height / 2.0;
    }

    console.log("Average = " + y);
  }

  this.distributeCoursesEvenly();
}

GraphLevel.prototype.distributeCoursesEvenly = function() {
  // Sort courses by Y
  this.courses.sort(function(a,b){b.y - a.y});

  // Distribute evenly
  //var step = (this.maxHeight - this.height) / (this.courses.length - 1)
  var y = this.maxHeight / 2.0 - this.height / 2;
  console.log("maxHeight = " + this.maxHeight);
  for (var course_index in this.courses) {
    var course = this.courses[course_index]
    course.y = y;
    y += course.getElement().height() + this.courseMargin;
  }
}


function GraphCourse(id, code, name) {
  this.element = false;
  this.id = id;
  this.code = code;
  this.name = name;

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

  var div = $('<div class="course"><h1>' + this.code + ' ' + this.name + '</h1></div>');
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

// GraphCourse.prototype.calculateVisibleNeighbors = function() {
//   for (var neighbor_index in course.prereqTo) {
//     var neighbor = course.prereqTo[neighbor_index];
//     if (neighbor.visible) {
//       this.visibleNeighborsForward++;
//     }
//   }
// }


// GraphCourse.prototype.getPrereqs = function() {
//   return this.prereqs;
// }
//
// /**
//  * Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
//  */
// GraphCourse.prototype.addPrereq = function(other) {
//   this.prereqs[other.code] = other;
//   other.prereqTo[this.code] = this;
// }
//
//
// GraphCourse.prototype.calculatePaths = function() {
//   this.dfsForward();
//   this.dfsBackward();
// }
//
// GraphCourse.prototype.render = function(c, view) {
//   // Box
//   c.strokeStyle = "#808080";
//   c.fillStyle = "#f0f0f0";
//   c.lineWidth = 1;
//   c.fillRect(this.x, this.y, view.courseWidth, view.courseHeight);
//   c.strokeRect(this.x, this.y, view.courseWidth, view.courseHeight);
//
//   // Texts
//   c.font = "10px sans-serif"
//   c.fillStyle = "#000000";
//   c.textBaseline = "top";
//   c.fillText(this.code, this.x + 2, this.y + 2);
// }
//
// GraphCourse.prototype.renderForward = function(c, view, depth) {
//   if (!this.onPath || this.visited) {
//     return;
//   }
//
//   this.visited = true;
//
//   // Visit neighbors
//   var requiredSpace = this.prereqToCount * (view.courseWidth + 10);
//   var i = 0;
//   for (array_index in this.prereqTo) {
//     var other = this.prereqTo[array_index];
//
//     // Position neighbor
//     if (!other.visited && other.onPath) {
//       //other.x = this.x - requiredSpace / 2 + i * (view.courseWidth + 10);
//     }
//
//     other.renderForward(c, view, depth+1);
//     i++;
//   }
//
//   // Arrows
//   if (depth == 1) {
//     c.strokeStyle = "#808080";
//   } else {
//     c.strokeStyle = "#ddd";
//   }
//   c.lineWidth = 1;
//   c.beginPath();
//   for (var index in this.prereqTo) {
//     var other = this.prereqTo[index];
//
//     c.moveTo(this.x + view.courseWidth / 2, this.y + view.courseHeight);
//     c.lineTo(other.x + view.courseWidth / 2, other.y);
//     //c.fillText(other.code, other.x + view.courseWidth / 2, other.y-20);
//     //c.fillText(other.period, other.x + view.courseWidth / 2, other.y-10);
//
//   }
//   c.stroke();
//
//   this.render(c, view);
// }
//
// GraphCourse.prototype.renderBackward = function(c, view, depth) {
//   // Visit
//   if (!this.onPath || this.visited) {
//     return;
//   }
//
//   this.visited = true;
//
//   // Visit neighbors
//   var requiredSpace = this.prereqsCount * (view.courseWidth + 10);
//   var i = 0;
//   for (array_index in this.prereqs) {
//     var other = this.prereqs[array_index];
//
//     // Position neighbor
//     if (!other.visited && other.onPath) {
//       //other.x = this.x - requiredSpace / 2 + i * (view.courseWidth + 10);
//     }
//
//     other.renderBackward(c, view,depth+1);
//     i++;
//   }
//
//   // Arrows
//   if (depth == 1) {
//     c.strokeStyle = "#808080";
//   } else {
//     c.strokeStyle = "#ddd";
//   }
//   c.lineWidth = 1;
//   c.beginPath();
//
//
//   for (var index in this.prereqs) {
//     var other = this.prereqs[index];
//
//     c.moveTo(this.x + view.courseWidth / 2, this.y);
//     c.lineTo(other.x + view.courseWidth / 2, other.y + view.courseHeight);
//   }
//   c.stroke();
//
//   this.render(c, view);
// }
//
// GraphCourse.prototype.dfsForward = function(c) {
//   // Visit
//   this.onPath = true;
//
//   // Visit neighbors
//   for (array_index in this.prereqTo) {
//     var other = this.prereqTo[array_index];
//     other.dfsForward();
//     this.prereqToCount++;
//   }
// }
//
// GraphCourse.prototype.dfsBackward = function(c) {
//   // Visit
//   this.onPath = true;
//
//   // Visit neighbors
//   for (array_index in this.prereqs) {
//     var other = this.prereqs[array_index];
//     other.dfsBackward();
//     this.prereqsCount++;
//   }
// }
