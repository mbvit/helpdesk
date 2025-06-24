class Api::V1::Accounts::ConversationEscalationsController < ApplicationController
  before_action :set_conversation
 
  def pause
    escalation = @conversation.conversation_escalations.find_by(status: 'pending')
 
    unless escalation
      return render json: { message: 'No active escalation to pause' }, status: :unprocessable_entity
    end
 
    service = Conversations::EscalationService.new(@conversation)
    service.pause_escalation_chain(escalation)
 
    render json: { message: 'Escalation paused successfully' }, status: :ok
    
  end
 
  def resume
    escalation = @conversation.conversation_escalations.find_by(status: 'paused')
 
    unless escalation
      return render json: { message: 'No paused escalation to resume' }, status: :unprocessable_entity
    end
 
    service = Conversations::EscalationService.new(@conversation)
    service.resume_escalation_chain(escalation)
 
    render json: { message: 'Escalation resumed successfully' }, status: :ok
  end
 
  private
 
  def set_conversation
    @conversation = Conversation.find_by(display_id: params[:id])
  end
end