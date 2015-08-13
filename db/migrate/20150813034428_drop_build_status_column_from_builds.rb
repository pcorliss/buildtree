class DropBuildStatusColumnFromBuilds < ActiveRecord::Migration
  def change
    remove_column :builds, :build_status
  end
end
