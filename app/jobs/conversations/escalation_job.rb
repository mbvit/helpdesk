class Conversations::EscalationJob < ApplicationJob
  queue_as :high

  def perform(escalation_id)
    escalation = ConversationEscalation.find_by(id: escalation_id)
    return if escalation.blank? || escalation.status != 'pending'

    conversation = escalation.conversation
    return if conversation.blank?

    # Assign the team
    conversation.update!(team_id: escalation.team_id)

    # Mark escalation as completed
    escalation.update!(status: 'completed')
  end
end
