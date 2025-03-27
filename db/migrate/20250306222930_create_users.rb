class CreateUser < ActiveRecord::Migration[7.2]
  def change
    create_table :user, id: false do |t|
      t.integer :user_id, primary_key: true
      t.string :username, null: false
      t.string :email, null: false
      t.string :pw_hash, null: false
    end
  end
end
