
var skillGraphView = {
  //svgNS: "http://www.w3.org/2000/svg",
  courses: {},     // id -> course object
  competences: {}, // id -> course object
  skills: {},      // id -> skill object

  initialize: function() {
    this.paper = Raphael(document.getElementById('svg'), 100, 100);
  },

  load: function(coursesPath, competencesPath, skillsPath) {
    $.ajax({
      url: coursesPath,
      context: this,
      dataType: 'json',
      success: this.loadCourses,
      async: false
    });

    $.ajax({
      url: competencesPath,
      context: this,
      dataType: 'json',
      success: this.loadCompetences,
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
    for (var array_index in data) {
      var rawData = data[array_index].scoped_course;

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
  },

  /**
   * Loads competences from JSON data.
   */
  loadCompetences: function(data) {
    for (var array_index in data) {
      var rawData = data[array_index].competence;

      //var periodId = parseInt(rawData.period_id);
      var course = new GraphCourse('c' + rawData.id, '', rawData.translated_name);
      course.setCompetence(true);
      this.courses['c' + rawData.id] = course;
    }

    // Set connections between courses
    for (var array_index in data) {
      rawData = data[array_index].competence;
      course = this.courses['c' + rawData.id];

      for (var array_index2 in rawData.strict_prereq_ids) {
        var prereq = this.courses[rawData.strict_prereq_ids[array_index2]];
        console.log("Competence prereq: " + prereq.name)

        if (prereq) {
          course.addPrereq(prereq);
        }
      }
    }
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
      var course = false;
      if (rawData.skillable_type == 'ScopedCourse') {
        var course = this.courses[rawData.skillable_id];
      } else if (rawData.skillable_type == 'Competence') {
        var course = this.courses['c' + rawData.skillable_id];
      }

      if (!course) {
        continue;
      }

      course.addSkill(skill);
      skill.setCourse(course);
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

    //this.attachCourse(targetCourse);


    // Run through course graph with DFS to find out which courses are visible
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
      course.visited = true;

      // Add neighbors to stack
      for (var array_index in course.prereqs) {
        stack.push(course.prereqs[array_index]);
      }
    }

    // DFS forward
    stack = [targetCourse];
    targetCourse.visited = false;
    while (stack.length > 0) {
      var course = stack.pop();

      if (course.visited) {
        continue;
      }

      // Visit node
      //levels[1][course.id] = course;
      courses[course.id] = course;
      course.visible = true;
      course.visited = true;

      // Add neighbors to stack
      for (var array_index in course.prereqTo) {
        stack.push(course.prereqTo[array_index]);
      }
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
    var maxHeight = $(document).height();
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


    // Set Y indices
    for (var level_index = targetCourse.level; level_index < this.levels.length; level_index++) {
      this.levels[level_index].setYindicesBackwards();
    }

    for (var level_index = targetCourse.level - 1; level_index >= 0; level_index--) {
      this.levels[level_index].setYindicesForward();
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
};


$(document).ready(function(){
  var element = $('#course-graph');
  var coursesPath = element.data('courses-path');
  var competencesPath = element.data('competences-path');
  var skillsPath = element.data('skills-path');

  skillGraphView.initialize();
  skillGraphView.load(coursesPath, competencesPath, skillsPath);
  skillGraphView.initializeVisualization(element.data('course-id')); // parseInt
});
