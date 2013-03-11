class AddCommentToScopedCourse < ActiveRecord::Migration
  def change
    add_column :competence_nodes, :comments,        :text
  end
end
