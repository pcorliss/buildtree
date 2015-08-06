class AddColumnsToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :parent_id, :int
    add_column :builds, :top_parent_id, :int
    add_column :builds, :env, :string
    add_column :builds, :parallel, :boolean
    add_column :builds, :sub_project_path, :string
    add_column :builds, :build_success, :boolean
  end
end
