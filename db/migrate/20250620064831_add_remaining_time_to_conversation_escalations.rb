class AddRemainingTimeToConversationEscalations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_escalations, :remaining_time_in_seconds, :integer
  end
end
