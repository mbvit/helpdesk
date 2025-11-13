class AddTicketIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :ticket_id, :string
    add_index :conversations, :ticket_id, unique: true
  end
end
