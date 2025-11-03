class AddMergedWithInConversations < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversations, :merged_with, foreign_key: { to_table: :conversations }, index: true
  end
end
