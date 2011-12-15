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
          var from = skill.element.offset();
          var to = neighbor.element.offset();
          this.view.createLine(from.left, from.top + skill.element.height() / 2, to.left + neighbor.element.width(), to.top + neighbor.element.height() / 2, 1, false);
        }

        skill.visited = true;
      }
    }

    // Add neighbors to stack
    //console.log("starting stack");
    for (var array_index in skill.prereqs) {
      stack.push(skill.prereqs[array_index]);
    }
    //console.log("ending stack");
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

        //console.log(neighbor.description);

        if (neighbor.element && neighbor.course.visible) {
          var from = skill.element.offset();
          var to = neighbor.element.offset();
          this.view.createLine(from.left + skill.element.width(), from.top + skill.element.height() / 2, to.left, to.top + neighbor.element.height() / 2, 1, false);
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
