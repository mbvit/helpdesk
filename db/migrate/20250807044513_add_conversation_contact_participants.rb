class AddConversationContactParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_contact_participants do |t|
      t.references :account, null: false, foreign_key: true, type: :bigint
      t.references :contact, null: false, foreign_key: true, type: :bigint
      t.references :conversation, null: false, foreign_key: true, type: :bigint

      t.timestamps
    end
    add_index :conversation_contact_participants, [:conversation_id, :contact_id], unique: true

  end
end
