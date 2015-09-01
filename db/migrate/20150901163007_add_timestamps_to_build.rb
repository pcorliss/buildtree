class AddTimestampsToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :started_at, :datetime
    add_column :builds, :completed_at, :datetime
  end
end
