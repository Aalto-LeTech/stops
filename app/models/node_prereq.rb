# Join model that connects competence_nodes to competence_nodes (prerequisites)
class NodePrereq < ActiveRecord::Base
  self.table_name = "node_prereqs_cache"

  belongs_to :competence_node, :class_name => 'CompetenceNode', :foreign_key => 'competence_node_id'
  belongs_to :prereq, :class_name => 'CompetenceNode', :foreign_key => 'prereq_id'
end
