function PathViewer(element) {
  this.courseHeight = 20;
  this.courseWidth = 100;
  this.periodHeight = 50;
  this.iterationCounter = 0;
  
  element.data('object', this);     // Add a reference from element to this
  this.element = element;           // jQuery element
  
  this.context = element[0].getContext('2d');
  this.width = element[0].width;
  this.height = element[0].height;

  this.minPeriod = Number.MAX_VALUE;
  this.maxPeriod = Number.MIN_VALUE;
  this.rootCourse = false;
  
  this.courses = {};
  
  element.click(PathViewer.prototype.click);
  
  this.load();
  this.render();
  
  //var that = this;
  //this.animator = setInterval(function() { that.animate(); }, 100);
};

PathViewer.prototype.load = function() {
  // Load user's courses
  var userCoursesPath = this.element.data('user-courses-path');
  
  $.ajax({
    url: userCoursesPath,
    context: this,
    dataType: 'json',
    success: this.loadUserCourses,
    async: false
  });
  
  // Load prereq graph
  var prereqsPath = this.element.data('prereqs-path');
  
  $.ajax({
    url: prereqsPath,
    context: this,
    dataType: 'json',
    success: this.loadPrereqs,
    async: false
  });
  
};

/**
 * Loads user's courses from JSON data.
 */
PathViewer.prototype.loadUserCourses = function(data) {
  for (var array_index in data) {
    var rawData = data[array_index].user_course;
    
    var periodId = parseInt(rawData.period_id);
    var course = new PathCourse(rawData.scoped_course_id, rawData.course_code, periodId);
    this.courses[rawData.scoped_course_id] = course;
    
    // Find max and min period. FIXME: should use numbers instead of ids.
    if (periodId > this.maxPeriod) {
      this.maxPeriod = periodId;
    }
    
    if (periodId < this.minPeriod) {
      this.minPeriod = periodId;
    }
  }
  
  this.periodHeight = this.height / (this.maxPeriod - this.minPeriod + 1);
  this.courseHeight = this.periodHeight - 4;
  var courseYoffset = (this.courseHeight - this.periodHeight) / 2;
  
  // Set coordinates
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    
    if (course.period === false) {
      continue;
    }
    
    var period = course.period - this.minPeriod;
    course.y = this.periodHeight * period - courseYoffset;
    course.x = Math.random() * this.height;
  }
  
  
  
}

/**
 * Loads prereqs from JSON data.
 */
PathViewer.prototype.loadPrereqs = function(data) {
  // Set prereqs
  for (var array_index in data) {
    var rawData = data[array_index].course_prereq;
    
    var course = this.courses[rawData.course_id];
    var prereq = this.courses[rawData.prereq_id]
    
    if (!prereq || !course) {
      continue;
    }
    
    course.addPrereq(prereq);
  }
  
  // Calculate paths
  var rootCourseId = this.element.data('course');
  this.rootCourse = this.courses[rootCourseId];
  this.rootCourse.x = (this.width - this.courseWidth) / 2;
  this.rootCourse.calculatePaths();
};

PathViewer.prototype.animate = function() {
  this.render();
  this.iterationCounter++;
  
  if (this.iterationCounter > 100) {
    clearInterval(this.animator);
  }
  
  // Move courses
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    course.visited = false;
    var force = 0.0;
    
    // Spring forces
    for (array_index in course.prereqTo) {
      var other = course.prereqTo[array_index];
      force += (other.x - course.x) / 50.0;
    }
    
    for (array_index in course.prereqs) {
      var other = course.prereqs[array_index];
      force += (other.x - course.x) / 50.0;
    }
    
    // Electric forces
    for (var array_index in this.courses) {
      var other = this.courses[array_index];
      if (course == other ||
          (course.period < this.rootCourse.period && other.period > this.rootCourse.period) || 
          (course.period > this.rootCourse.period && other.period < this.rootCourse.period)) { // || course.period != other.period
        continue;
      }

      if (other.x > course.x && other.x < course.x + this.courseWidth * 2) {
        force += (this.courseWidth * 2 - (other.x - course.x)) / 500.0;
      }
      if (other.x < course.x && other.x > course.x - this.courseWidth * 2) {
        force -= (this.courseWidth * 2 - (course.x - other.x)) / 500.0;
      }
    }
    
    course.x += force;
  }

  this.rootCourse.x = (this.width - this.courseWidth) / 2;

}

PathViewer.prototype.clear = function(c) {
  
}

PathViewer.prototype.render = function() {
  var c = this.context;
  
  // Clear
  c.fillStyle = "#fff";
  c.fillRect(0, 0, this.width, this.height);
  
  // Periods
  c.strokeStyle = "#d0d0d0";
  c.beginPath();
  for (var i=this.minPeriod; i<this.maxPeriod; i++) {
    c.moveTo(0, i * this.periodHeight);
    c.lineTo(this.width, i * this.periodHeight);
  }
  c.stroke();
  
  
  this.rootCourse.renderBackward(c, this, 1);
  this.rootCourse.visited = false;
  this.rootCourse.renderForward(c, this, 1);
  
  // Hilight root course
  c.strokeStyle = "#8080ff";
  c.fillStyle = "#a0a0ff";
  c.lineWidth = 1;
  c.fillRect(this.rootCourse.x, this.rootCourse.y, this.courseWidth, this.courseHeight);
  c.strokeRect(this.rootCourse.x, this.rootCourse.y, this.courseWidth, this.courseHeight);
    
  // Texts
  c.font = "10px sans-serif"
  c.fillStyle = "#000000";
  c.textBaseline = "top";
  c.fillText(this.rootCourse.course_code, this.rootCourse.x + 2, this.rootCourse.y + 2);
  
  return;
  
  // Arrows
  c.strokeStyle = "#808080";
  c.lineWidth = 1;
  c.beginPath();
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    
    if (!course.onPath) {
      continue;
    }
    
    var prereqs = course.getPrereqs();
    for (var prereq_index in prereqs) {
      var prereq = prereqs[prereq_index];
      
      if (!prereq.onPath) {
        continue;
      }
      
      c.moveTo(course.x + this.courseWidth / 2, course.y);
      c.lineTo(prereq.x + this.courseWidth / 2, prereq.y + this.courseHeight);
    }
  }
  c.stroke();
  
  // Boxes
  c.strokeStyle = "#808080";
  c.fillStyle = "#f0f0f0";
  c.lineWidth = 1;
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    if (!course.onPath) {
      continue;
    }
    
    c.fillRect(course.x, course.y, this.courseWidth, this.courseHeight);
    c.strokeRect(course.x, course.y, this.courseWidth, this.courseHeight);
  }
  
  // Root course
  c.strokeStyle = "#8080ff";
  c.fillStyle = "#a0a0ff";
  c.fillRect(this.rootCourse.x, this.rootCourse.y, this.courseWidth, this.courseHeight);
  c.strokeRect(this.rootCourse.x, this.rootCourse.y, this.courseWidth, this.courseHeight);
  
    
  // Texts
  c.font = "10px sans-serif"
  c.fillStyle = "#000000";
  c.textBaseline = "top";
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    if (!course.onPath) {
      continue;
    }
    
    c.fillText(course.course_code, course.x + 2, course.y + 2);
  }
  
};


// Event listener
PathViewer.prototype.click = function() {
};
