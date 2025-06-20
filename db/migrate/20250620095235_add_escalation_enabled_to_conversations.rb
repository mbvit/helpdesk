class AddEscalationEnabledToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :escalation_enabled, :boolean, default: false
  end
end
