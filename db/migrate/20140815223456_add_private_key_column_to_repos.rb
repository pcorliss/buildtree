class AddPrivateKeyColumnToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :private_key, :text, :limit => 4096
  end
end
