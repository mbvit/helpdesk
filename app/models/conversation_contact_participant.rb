class ConversationContactParticipant < ApplicationRecord
  # -- Associations --
  belongs_to :account
  belongs_to :conversation
  belongs_to :contact

  # -- Validations --
  # Ensures that you can't add the same contact to the same conversation more than once.
    
  validates :contact_id, uniqueness: { scope: :conversation_id }
end