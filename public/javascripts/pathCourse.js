function PathCourse(id, code, period) {
  this.id = id;
  this.code = code;
  this.period = period;
  this.onPath = false;
  this.visited = false;
  this.prereqs = {};           // Prerequisite courses. courseCode => course object
  this.prereqTo = {};          // Courses for which this course is a prereq. courseCode => course object
  this.prereqsCount = 0;
  this.prereqToCount = 0;

  this.x = 0;
  this.y = 0;
  
};


PathCourse.prototype.getPrereqs = function() {
  return this.prereqs;
}

/**
 * Adds a prerequisite course. This course is automatically added to the "prerequisite to" list of the other course.
 */
PathCourse.prototype.addPrereq = function(other) {
  this.prereqs[other.code] = other;
  other.prereqTo[this.code] = this;
}


PathCourse.prototype.calculatePaths = function() {
  this.dfsForward();
  this.dfsBackward();
}

PathCourse.prototype.render = function(c, view) {
  // Box
  c.strokeStyle = "#808080";
  c.fillStyle = "#f0f0f0";
  c.lineWidth = 1;
  c.fillRect(this.x, this.y, view.courseWidth, view.courseHeight);
  c.strokeRect(this.x, this.y, view.courseWidth, view.courseHeight);
    
  // Texts
  c.font = "10px sans-serif"
  c.fillStyle = "#000000";
  c.textBaseline = "top";
  c.fillText(this.code, this.x + 2, this.y + 2);
}

PathCourse.prototype.renderForward = function(c, view, depth) {
  if (!this.onPath || this.visited) {
    return;
  }
  
  this.visited = true;
  
  // Visit neighbors
  var requiredSpace = this.prereqToCount * (view.courseWidth + 10);
  var i = 0;
  for (array_index in this.prereqTo) {
    var other = this.prereqTo[array_index];
    
    // Position neighbor
    if (!other.visited && other.onPath) {
      //other.x = this.x - requiredSpace / 2 + i * (view.courseWidth + 10);
    }
    
    other.renderForward(c, view, depth+1);
    i++;
  }
  
  // Arrows
  if (depth == 1) {
    c.strokeStyle = "#808080";
  } else {
    c.strokeStyle = "#ddd";
  }
  c.lineWidth = 1;
  c.beginPath();
  for (var index in this.prereqTo) {
    var other = this.prereqTo[index];
    
    c.moveTo(this.x + view.courseWidth / 2, this.y + view.courseHeight);
    c.lineTo(other.x + view.courseWidth / 2, other.y);
    //c.fillText(other.code, other.x + view.courseWidth / 2, other.y-20);
    //c.fillText(other.period, other.x + view.courseWidth / 2, other.y-10);
    
  }
  c.stroke();
  
  this.render(c, view);
}

PathCourse.prototype.renderBackward = function(c, view, depth) {
  // Visit
  if (!this.onPath || this.visited) {
    return;
  }

  this.visited = true;
  
  // Visit neighbors
  var requiredSpace = this.prereqsCount * (view.courseWidth + 10);
  var i = 0;
  for (array_index in this.prereqs) {
    var other = this.prereqs[array_index];

    // Position neighbor
    if (!other.visited && other.onPath) {
      //other.x = this.x - requiredSpace / 2 + i * (view.courseWidth + 10);
    }

    other.renderBackward(c, view,depth+1);
    i++;
  }
  
  // Arrows
  if (depth == 1) {
    c.strokeStyle = "#808080";
  } else {
    c.strokeStyle = "#ddd";
  }
  c.lineWidth = 1;
  c.beginPath();
  
  
  for (var index in this.prereqs) {
    var other = this.prereqs[index];
    
    c.moveTo(this.x + view.courseWidth / 2, this.y);
    c.lineTo(other.x + view.courseWidth / 2, other.y + view.courseHeight);
  }
  c.stroke();

  this.render(c, view);
}

PathCourse.prototype.dfsForward = function(c) {
  // Visit
  this.onPath = true;    
  
  // Visit neighbors
  for (array_index in this.prereqTo) {
    var other = this.prereqTo[array_index];
    other.dfsForward();
    this.prereqToCount++;
  }  
}

PathCourse.prototype.dfsBackward = function(c) {
  // Visit
  this.onPath = true;
  
  // Visit neighbors
  for (array_index in this.prereqs) {
    var other = this.prereqs[array_index];
    other.dfsBackward();
    this.prereqsCount++;
  }
}
