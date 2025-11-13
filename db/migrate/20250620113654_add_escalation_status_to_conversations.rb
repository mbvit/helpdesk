class AddEscalationStatusToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :escalation_status, :string, default: 'none'
  end
end
