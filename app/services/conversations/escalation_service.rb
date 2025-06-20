class Conversations::EscalationService
  def initialize(conversation)
    @conversation = conversation
  end

  def pause_escalation_chain(escalation)
    return unless escalation.status == 'pending'

    # Calculate remaining time for this escalation
    remaining_time = escalation.scheduled_at - Time.current

    escalation.update!(
      remaining_time_in_seconds: remaining_time.to_i,
      status: 'paused'
    )

    # Also pause all upcoming escalations
    upcoming_escalations = escalation.conversation.conversation_escalations
                                     .where('scheduled_at > ?', escalation.scheduled_at)
                                     .where(status: 'pending')

    upcoming_escalations.each do |future_escalation|
      remaining_time = future_escalation.scheduled_at - Time.current
      future_escalation.update!(
        remaining_time_in_seconds: remaining_time.to_i,
        status: 'paused'
      )
    end
  end

  def resume_escalation_chain(escalation)
    return unless escalation.status == 'paused'

    # Resume the paused escalation first
    ::Conversations::EscalationJob.set(wait: escalation.remaining_time_in_seconds.seconds).perform_later(escalation.id)

    escalation.update!(
      status: 'pending',
      scheduled_at: Time.current + escalation.remaining_time_in_seconds.seconds
    )

    # Also resume all upcoming escalations in correct order

    # Fetch upcoming escalations sorted by created_at (order matters)
    upcoming_escalations = escalation.conversation.conversation_escalations
                                     .where('scheduled_at > ?', escalation.scheduled_at)
                                     .where(status: 'paused')
                                     .order(:scheduled_at)

    # Keep a cumulative time to schedule next escalations in sequence
    cumulative_delay = escalation.remaining_time_in_seconds

    upcoming_escalations.each do |future_escalation|
      # Schedule this escalation after cumulative_delay
      ::Conversations::EscalationJob.set(wait: cumulative_delay.seconds).perform_later(future_escalation.id)

      # Update the escalation record
      future_escalation.update!(
        status: 'pending',
        scheduled_at: Time.current + cumulative_delay.seconds
      )

      # Add this escalation's original delay to cumulative_delay
      cumulative_delay += future_escalation.delay_in_seconds
    end
  end
end
