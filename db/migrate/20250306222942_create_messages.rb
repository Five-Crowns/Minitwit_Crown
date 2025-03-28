class CreateMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :messages, id: false do |t|
      t.integer :message_id, primary_key: true
      t.integer :author_id, null: false
      t.string :text, null: false
      t.integer :pub_date
      t.integer :flagged, default: 0
    end
  end
end
