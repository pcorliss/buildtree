class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.integer :repo_id
      t.string :branch
      t.string :sha, limit: 40
      t.boolean :success

      t.timestamps null: false
    end
  end
end
