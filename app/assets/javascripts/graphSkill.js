function GraphSkill(id, position, description) {
  this.element = false;
  this.id = id;
  this.position = position;
  this.description = description;
  this.course = false;
  this.visited = false;

  this.prereqs = [];
  this.prereqTo = [];
};

GraphSkill.prototype.setCourse = function(course) {
  this.course = course;
}

GraphSkill.prototype.addPrereq = function(skill) {
  this.prereqs.push(skill);
  skill.prereqTo.push(this);
}

GraphSkill.prototype.click = function(event) {
  // Reset hilights and SVG
  this.view.resetHilights();

  this.dfsBackward(true);
  this.visited = false;
  this.dfsForward(true);

  this.view.resetVisitedSkills();

  return false;
}

GraphSkill.prototype.dfsBackward = function(drawEdges) {
  // Run DFS
  var stack = [this];
  var level = 0;
  
  while (stack.length > 0) {
    var skill = stack.pop();
    // Hilight node
    if (skill.visited || !skill.element) {
      continue;
    }

    skill.element.addClass('hilight');

    // Draw edges to forward neighbors
    if (drawEdges) {
      for (var neighbor_index in skill.prereqs) {
        var neighbor = skill.prereqs[neighbor_index];

        if (neighbor.element && neighbor.course.visible) {
          var from = skill.element.position();
          var to = neighbor.element.position();
          
          this.view.createLine(
            from.left + skill.course.x,
            from.top + skill.course.y + skill.element.height() / 2,
            to.left + neighbor.course.x + neighbor.element.width(),
            to.top + neighbor.course.y + neighbor.element.height() / 2, 1, false);
        }

        skill.visited = true;
      }
    }

    // Add neighbors to stack
    for (var array_index in skill.prereqs) {
      var neighbor = skill.prereqs[array_index];
      stack.push(neighbor);
      
      if (level == 0) {
        neighbor.element.addClass('hilight-strong');
      }
    }
    level++;
  }
}


GraphSkill.prototype.dfsForward = function(drawEdges) {
  // Run DFS
  var stack = [this];

  while (stack.length > 0) {
    var skill = stack.pop();
    // Hilight node
    if (skill.visited || !skill.element) {
      continue;
    }

    skill.element.addClass('hilight');

    // Draw edges to forward neighbors
    if (drawEdges) {
      for (var neighbor_index in skill.prereqTo) {
        var neighbor = skill.prereqTo[neighbor_index];

        if (neighbor.element && neighbor.course.visible) {
          var from = skill.element.position();
          var to = neighbor.element.position();
          
          this.view.createLine(
            from.left + skill.course.x + skill.element.width(),
            from.top + skill.course.y + skill.element.height() / 2,
            to.left + neighbor.course.x,
            to.top + neighbor.course.y + neighbor.element.height() / 2, 1, false);
        }
      }
    }

    skill.visited = true;

    // Add neighbors to stack
    for (var array_index in skill.prereqTo) {
      stack.push(skill.prereqTo[array_index]);
    }
  }
}
