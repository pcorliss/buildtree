class CreateUsers2 < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :provider
      t.string :uid
      t.string :email
      t.string :avatar
      t.string :token
      t.string :secret

      t.timestamps
    end
  end
end
