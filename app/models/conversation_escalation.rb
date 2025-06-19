# == Schema Information
#
# Table name: conversation_escalations
#
#  id               :bigint           not null, primary key
#  delay_in_seconds :integer
#  scheduled_at     :datetime
#  status           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  conversation_id  :bigint           not null
#  team_id          :integer
#
# Indexes
#
#  index_conversation_escalations_on_conversation_id  (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#
class ConversationEscalation < ApplicationRecord
  belongs_to :conversation
end
