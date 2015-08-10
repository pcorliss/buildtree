class AddStatusToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :status, :integer, default: 0
    add_column :builds, :build_status, :integer, default: 0
    remove_column :builds, :success
    remove_column :builds, :build_success
  end
end
