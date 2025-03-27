class CreateMessage < ActiveRecord::Migration[7.2]
  def change
    create_table :messages do |t|
      create_table :message, id: false do |t|
        t.integer :message_id, primary_key: true
        t.integer :author_id, null: false
        t.string :text, null: false
        t.integer :pub_date
        t.integer :flagged
    end
  end
end
