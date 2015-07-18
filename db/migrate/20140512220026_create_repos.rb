class CreateRepos < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.string :service
      t.string :organization
      t.string :name

      t.timestamps
    end
  end
end
