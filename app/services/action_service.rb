class ActionService
  include EmailHelper

  def initialize(conversation)
    @conversation = conversation.reload
    @account = @conversation.account
  end

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.snoozed!
  end

  def resolve_conversation(_params)
    @conversation.resolved!
  end

  def open_conversation(_params)
    @conversation.open!
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def change_priority(priority)
    @conversation.update!(priority: (priority[0] == 'nil' ? nil : priority[0]))
  end

  def add_label(labels)
    return if labels.empty?

    @conversation.reload.add_labels(labels)
  end

  def assign_agent(agent_ids = [])
    return @conversation.update!(assignee_id: nil) if agent_ids[0] == 'nil'

    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)

    @conversation.update!(assignee_id: @agent.id) if @agent.present?
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update(label_list: labels)
  end

  def assign_team(team_ids = [])
    # FIXME: The explicit checks for zero or nil (string) is bad. Move
    # this to a separate unassign action.
    should_unassign = team_ids.blank? || %w[nil 0].include?(team_ids[0].to_s)
    return @conversation.update!(team_id: nil) if should_unassign

    # check if team belongs to account only if team_id is present
    # if team_id is nil, then it means that the team is being unassigned
    return unless !team_ids[0].nil? && team_belongs_to_account?(team_ids)

    @conversation.update!(team_id: team_ids[0])
  end

  def ticket_escalation(escalate_step)
    @conversation.update!(escalation_status: 'running') if @conversation.escalation_status == 'no_escalation'

    team_id = escalate_step[0]
    delay_in_seconds = convert_to_seconds(escalate_step[1], escalate_step[2])

    return if team_id.blank? || %w[nil 0].include?(team_id.to_s)

    total_previous_delay = @conversation.conversation_escalations.sum(:delay_in_seconds)

    cumulative_delay = total_previous_delay

    scheduled_time = @conversation.created_at + cumulative_delay.seconds

    # Save escalation step
    escalation = @conversation.conversation_escalations.create!(
      team_id: team_id,
      delay_in_seconds: delay_in_seconds.to_i, # Only current step's delay
      status: 'pending',
      scheduled_at: scheduled_time
    )

    # Schedule the job using cumulative delay (wait from now)
    ::Conversations::EscalationJob.set(wait: cumulative_delay.seconds).perform_later(escalation.id)
  end

  def remove_assigned_team(_params)
    @conversation.update!(team_id: nil)
  end

  def send_email_transcript(emails)
    emails = emails[0].gsub(/\s+/, '').split(',')

    emails.each do |email|
      email = parse_email_variables(@conversation, email)
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
    end
  end

  private

  def agent_belongs_to_inbox?(agent_ids)
    member_ids = @conversation.inbox.members.pluck(:user_id)
    assignable_agent_ids = member_ids + @account.administrators.ids

    assignable_agent_ids.include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def conversation_a_tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end
end

def convert_to_seconds(value, unit)
  return 0 unless value.is_a?(Numeric) && value >= 0
  return 0 unless unit.is_a?(String)

  normalized_unit = unit.strip.downcase

  case normalized_unit
  when 'second', 'seconds'
    value
  when 'minute', 'minutes', 'min'
    value * 60
  when 'hour', 'hours', 'hr', 'hoours' # typo fallback
    value * 3600
  when 'day', 'days'
    value * 86400
  else
    warn "Unknown time unit: #{unit}"
    0
  end
end


ActionService.include_mod_with('ActionService')
