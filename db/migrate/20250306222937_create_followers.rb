class CreateFollower < ActiveRecord::Migration[7.2]
  def change
    create_table :follower, id: false do |t|
      t.integer :who_id, null: false
      t.integer :whom_id, null: false

      t.index [:who_id, :whom_id], unique: true  # Prevents duplicate follow relationships
    end
  end
end
