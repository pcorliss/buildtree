class DropTopParentColumnFromBuild < ActiveRecord::Migration
  def change
    remove_column :builds, :top_parent_id
  end
end
