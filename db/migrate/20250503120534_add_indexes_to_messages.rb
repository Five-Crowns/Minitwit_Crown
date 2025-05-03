class AddIndexesToMessages < ActiveRecord::Migration[6.1]
    def change
      add_index :messages, :flagged
      add_index :messages, :author_id
      add_index :messages, :pub_date
      add_index :messages, [:flagged, :pub_date]
    end
  end