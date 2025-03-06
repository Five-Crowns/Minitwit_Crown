class CreateFollowers < ActiveRecord::Migration[7.2]
  def change
    create_table :followers, id: false do |t|  # No primary key
      t.integer :who_id, null: false
      t.integer :whom_id, null: false

      t.index [:who_id, :whom_id], unique: true  # Prevents duplicate follow relationships
    end
  end
end
