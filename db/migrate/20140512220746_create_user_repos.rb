class CreateUserRepos < ActiveRecord::Migration
  def change
    create_table :user_repos do |t|
      t.integer :user_id
      t.integer :repo_id

      t.timestamps
    end
  end
end
