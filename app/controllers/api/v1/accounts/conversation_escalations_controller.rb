class ConversationEscalationsController < ApplicationController
  before_action :set_escalation, only: [:pause, :resume]

  def pause
    service = Conversations::EscalationService.new(@escalation.conversation)
    service.pause_escalation_chain(@escalation)

    render json: { message: 'Escalation paused successfully' }, status: :ok
  end

  def resume
    service = Conversations::EscalationService.new(@escalation.conversation)
    service.resume_escalation_chain(@escalation)

    render json: { message: 'Escalation resumed successfully' }, status: :ok
  end

  private

  def set_escalation
    @escalation = ConversationEscalation.find(params[:id])
  end
end
