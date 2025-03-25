class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|  # ActiveRecord expects `id` as primary key by default
      t.string :username, null: false
      t.string :email, null: false
      t.string :pw_hash, null: false

      t.timestamps  # Adds created_at and updated_at columns
    end
  end
end
