class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.integer :author_id, null: false
      t.string :text, null: false
      t.integer :pub_date
      t.integer :flagged, default: 0

      t.timestamps  # Adds created_at and updated_at
    end
  end
end
