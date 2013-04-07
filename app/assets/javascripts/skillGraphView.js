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

      var course = new GraphCourse(rawData.id, rawData.course_code, rawData.translated_name);
      this.courses[rawData.id] = course;
    }

    // Set connections between courses
    /*
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
    */
  },

  /**
   * Loads competences from JSON data.
   */
  loadCompetences: function(data) {
    for (var array_index in data) {
      var rawData = data[array_index].competence;

      //var periodId = parseInt(rawData.period_id);
      var course = new GraphCourse(rawData.id, '', rawData.translated_name);
      course.setCompetence(true);
      this.courses[rawData.id] = course;
    }

    // Set connections between courses
    /*
    for (var array_index in data) {
      rawData = data[array_index].competence;
      course = this.courses[rawData.id];

      for (var array_index2 in rawData.strict_prereq_ids) {
        var prereq = this.courses[rawData.strict_prereq_ids[array_index2]];
        console.log("Competence prereq: " + prereq.name)

        if (prereq) {
          course.addPrereq(prereq);
        }
      }
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

      // Skip if skills belongs to a course that is not shown
      var course = this.courses[rawData.competence_node_id];
      if (!course) {
        continue;
      }
      
      // Skip skill if localized text is not available
      if (!rawData.description_with_locale) {
        continue;
      }
      
      var localized_name = rawData.description_with_locale.skill_description.description;
      
      // Create skill object
      var skill = new GraphSkill(rawData.id, rawData.position, localized_name);
      this.skills[rawData.id] = skill;

      // Add skill to course
      course.addSkill(skill);
      skill.setCourse(course);
    }

    // Set connections between skills
    for (var array_index in data) {
      var rawData = data[array_index].skill;
      var skill = this.skills[rawData.id];

      for (var array_index2 in rawData.strict_prereq_ids) {
        var prereq = this.skills[rawData.strict_prereq_ids[array_index2]];

        if (prereq) {
          skill.addPrereq(prereq);
          skill.course.addPrereq(prereq.course)
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
  
  resetVisitedCourses: function() {
    for (var array_index in this.courses) {
      var course = this.courses[array_index];
      course.visited = false;
    }
  },

  initializeVisualization: function(courseId) {
    var targetCourse = this.courses[courseId];
    if (!targetCourse) {
      return;
    }

    //this.attachCourse(targetCourse);

    
    // Run through course graph with DFS to find out which courses are visible
    // and to assign level numbers
    var minLevel = 0;
    var maxLevel = 0;
    
    targetCourse.dfs('backward', 0, function(course, level) {
      course.visible = true;
      if (level < course.level) {
        course.level = level;
      }
      if (course.level < minLevel) {
        minLevel = course.level;
      }
    });
    targetCourse.dfs('forward', 0, function(course, level) {
      course.visible = true;
      if (level > course.level) {
        course.level = level;
      }
      if (course.level > maxLevel) {
        maxLevel = course.level;
      }
    });


    // Create levels
    var levelCount = maxLevel - minLevel + 1;
    this.levels = Array(levelCount);
    for (var i = 0; i < levelCount; i++) {
      var level = new GraphLevel(i);
      this.levels[i] = level;
    }


    // Add courses to levels and the view
    var levelWidth = 600;

    for (var array_index in this.courses) {
      var course = this.courses[array_index];
      course.level -= minLevel;  // Update course level numbers so that they start from zero
      
      if (!course.visible) {
        continue;
      }
      
      this.attachCourse(course);
      level = this.levels[course.level];
      if (level) {
        level.addCourse(course);
      }

      var x = course.level * levelWidth;
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

    targetCourse.y = (maxHeight + targetCourse.getElement(this).height()) / 2;


    // Set Y indices
    for (var level_index = 0; level_index < this.levels.length; level_index++) {
      this.levels[level_index].setYindicesBackwards();
    }

    for (var level_index = this.levels.length - 1; level_index >= 0; level_index--) {
      this.levels[level_index].setYindicesForward();
    }

    // Updating positions
    for (var course_index in this.courses) {
      var course = this.courses[course_index];
      if (!course.visible) {
        continue;
      }
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
