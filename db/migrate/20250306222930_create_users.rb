class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: false do |t|  # ActiveRecord expects `id` as primary key by default
      t.integer :user_id, primary_key: true
      t.string :username, null: false
      t.string :email, null: false
      t.string :pw_hash, null: false
    end
  end
end
