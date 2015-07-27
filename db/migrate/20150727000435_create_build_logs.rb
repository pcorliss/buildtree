class CreateBuildLogs < ActiveRecord::Migration
  def change
    create_table :build_logs do |t|
      t.integer :build_id
      t.text :text
      t.string :cmd
      t.integer :exit_code

      t.timestamps null: false
    end
  end
end
