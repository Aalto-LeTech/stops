function PathViewer(element) {
  element.data('object', this);     // Add a reference from element to this
  this.element = element;           // jQuery element
  
  this.context = element[0].getContext('2d');
  this.width = element[0].width;
  this.height = element[0].height;

  this.courses = {};
  
  element.click(PathViewer.prototype.click);
  
  this.load();
  this.render();
};

PathViewer.prototype.load = function() {
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
   * Loads prereqs from JSON data.
   */
PathViewer.prototype.loadPrereqs = function(data) {
  for (var array_index in data) {
    var rawData = data[array_index].course_prereq;
    
    // TODO: would be better to have a dictionary for storing Course objects
    var course = new PathCourse(rawData.course_code);
    this.courses[rawData.id] = course;
    
    course.x = Math.random() * this.width;
    course.y = Math.random() * this.height;
  }
  
};
  
  
PathViewer.prototype.render = function() {
  var g = this.context;
  
  // Boxes
  g.strokeStyle = "#808080";
  g.fillStyle = "#f0f0f0";
  g.lineWidth = 1;
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    
    g.fillRect(course.x, course.y, 100, 20);
    g.strokeRect(course.x, course.y, 100, 20);
    //context.beginPath();
    //context.closePath();
    //context.stroke();
    //context.fill();
  }
    
  // Texts
  g.font = "10px sans-serif"
  g.fillStyle = "#000000";
  g.textBaseline = "top";
  for (var array_index in this.courses) {
    var course = this.courses[array_index];
    g.fillText(course.code, course.x + 2, course.y + 2);
  }
  
  
  
};


// Event listener
PathViewer.prototype.click = function() {
};
