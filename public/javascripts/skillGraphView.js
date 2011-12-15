
var skillGraphView = {
  //svgNS: "http://www.w3.org/2000/svg",
  courses: {},  // id -> course object
  skills: {},   // id -> skill object

  initialize: function() {
    this.paper = Raphael(document.getElementById('svg'), 100, 100);
  },

  load: function(coursesPath, skillsPath) {
    $.ajax({
      url: coursesPath,
      context: this,
      dataType: 'json',
      success: this.loadCourses,
      async: false
    });

    $.ajax({
      url: skillsPath,
      context: this,
      dataType: 'json',
      success: this.loadSkills,
      async: false
    });
  },

  /**
   * Loads courses from JSON data.
   */
  loadCourses: function(data) {

//           $.each(data.items, function(i,item){
//             $("<img/>").attr("src", item.media.m).appendTo("#images");
//             if ( i == 3 ) return false;
//           });

    for (var array_index in data) {
      var rawData = data[array_index].scoped_course;

      //var periodId = parseInt(rawData.period_id);
      var course = new GraphCourse(rawData.id, rawData.code, rawData.translated_name);
      this.courses[rawData.id] = course;
    }

    // Set connections between courses
    for (var array_index in data) {
      rawData = data[array_index].scoped_course;
      course = this.courses[rawData.id];

      for (var array_index2 in rawData.strict_prereq_ids) {
        var prereq = this.courses[rawData.strict_prereq_ids[array_index2]];

        if (prereq) {
          course.addPrereq(prereq);
        }
      }
    }


    /*
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
    */


  },

  /**
   * Loads courses from JSON data.
   */
  loadSkills: function(data) {
    // Read JSON
    for (var array_index in data) {
      var rawData = data[array_index].skill;

      // Create skill object
      var skill = new GraphSkill(rawData.id, rawData.position, rawData.translated_name);
      this.skills[rawData.id] = skill;

      // Add skill to course
      if (rawData.skillable_type == 'ScopedCourse') {
        var course = this.courses[rawData.skillable_id];
        if (!course) {
          //console.log("Course "+rawData.skillable_id+" not found.");
          continue;
        }

        course.addSkill(skill);
        skill.setCourse(course);
      }
    }

    // Set connections between skills
    for (var array_index in data) {
      rawData = data[array_index].skill;
      skill = this.skills[rawData.id];

      for (var array_index2 in rawData.strict_prereq_ids) {
        var prereq = this.skills[rawData.strict_prereq_ids[array_index2]];

        if (prereq) {
          skill.addPrereq(prereq);
        }
      }
    }
  },

  resetVisitedSkills: function() {
    for (var array_index in this.skills) {
      var skill = this.skills[array_index];
      skill.visited = false;
    }
  },

  initializeVisualization: function(courseId) {
    var targetCourse = this.courses[courseId];

    if (!targetCourse) {
      //console.log("Target course "+courseId+" not found.");
      return;
    }

    this.attachCourse(targetCourse);


    // Run through course graph with DFS and add courses to level 1
    //var levels = [targetCourse, {}];
    var courses = {};
    var stack = [targetCourse];

    while (stack.length > 0) {
      var course = stack.pop();

      if (course.visited) {
        continue;
      }

      // Visit node
      //levels[1][course.id] = course;
      courses[course.id] = course;
      course.visible = true;

      // Add neighbors to stack
      for (var array_index in course.prereqs) {
        stack.push(course.prereqs[array_index]);
      }

      course.visited = true;
    }

    // Assign levels
    var level = 0;
    var nextLevel;

    do {
      nextLevel = false;

      // Iterate through every course in the level. Push its prereqs to the next level.
      for (var array_index in courses) {
        var course = courses[array_index];

        if (course.level == level) {
          for (var array_index2 in course.prereqs) {
            course.prereqs[array_index2].level = level + 1;
            nextLevel = true;
          }
        }
      }

      level++;
    } while(nextLevel);


    // Create levels
    var levels = level;
    this.levels = Array(levels);
    for (var i = 0; i < levels; i++) {
      var level = new GraphLevel(i);
      this.levels[i] = level;
    }


    // Add courses to levels and the view
    var levelWidth = 600;

    for (var array_index in courses) {
      var course = courses[array_index];
      this.attachCourse(course);
      this.levels[course.level].addCourse(course);

      var x = (levels - 1 - course.level) * levelWidth;
      var y = 0;
      course.setPosition(x, y);
    }

    // Calculate level heights
    var maxHeight = 0;
    for (var level_index in this.levels) {
      var height = this.levels[level_index].updateHeight();
      if (height > maxHeight) {
        maxHeight = height;
      }
    }

    for (var level_index in this.levels) {
      this.levels[level_index].maxHeight = maxHeight;
    }

    targetCourse.y = (maxHeight + targetCourse.getElement(this).height()) / 2


      /*
      for (var course_index in courses) {
        var course = courses[course_index];
      }
      */

    // Set Y indices
    for (var level_index = 0; level_index < this.levels.length; level_index++) {
      var level = this.levels[level_index];
      //var neighbor = this.levels[level - 1];

      level.setYindicesBackwards();
    }

    // Updating positions
    for (var course_index in courses) {
      var course = courses[course_index];
      course.updatePosition();
    }

    // Update svg size
    this.paper.setSize($(document).width(), $(document).height());
  },

  resetHilights: function() {
    $('#course-graph li').removeClass('hilight');
    this.paper.clear();
  },

  createLine: function(x1, y1, x2, y2, w, color) {
    var line = this.paper.path("M"+x1+" "+y1+"L"+x2+" "+y2);
    line.attr("stroke", "#888");

//     var line = document.createElementNS(this.svgNS, "line");
//
//     line.setAttributeNS(null, "x1", x1);
//     line.setAttributeNS(null, "y1", y1);
//     line.setAttributeNS(null, "x2", x2);
//     line.setAttributeNS(null, "y2", y2);
//     line.setAttributeNS(null, "stroke-width", w);
//
//     var color = "rgb(128,128,128)";
//     line.setAttributeNS(null,"stroke",color);
//
//     this.svg.appendChild(line);
  },

  visualize: function() {
    // Show:
    // show the target course

    // On click skill:
    // take the starting node
    // run DFS
    //   mark visited nodes
    //   assign levels
    //   keep track of maximum width
    // create divs and attach to DOM
    // set div positions
    // create edges
  },

  attachCourse: function(course) {
    var courseCanvas = $('#course-graph');

    var element = course.getElement(this);
    courseCanvas.append(element);
  },

  /*
  clickSkill: function(event) {
    // Reset hilights
    // Reset svg

    // Run DFS
    // hilight visited nodes
    // draw edges
  }
  */

};


$(document).ready(function(){
  var element = $('#course-graph');
//   if (element.length > 0) {
//     new PathViewer(element);
//   }

  skillGraphView.initialize();
  var coursesPath = element.data('courses-path');
  var skillsPath = element.data('skills-path');

  skillGraphView.load(coursesPath, skillsPath);
  skillGraphView.initializeVisualization(parseInt(element.data('course-id')));

});
