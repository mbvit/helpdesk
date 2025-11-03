class CreateConversationEscalations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_escalations do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :team_id
      t.integer :delay_in_seconds
      t.string :status
      t.datetime :scheduled_at

      t.timestamps
    end
  end
end
