class Conversations::ConversationMergeHandler
    def initialize(primary_conversation, conversations_to_merge, all_contacts)
      @primary_conversation = primary_conversation
      @conversations_to_merge = conversations_to_merge
    #   @current_user = current_user
      @all_contacts = all_contacts
    end
  
    def perform
        ActiveRecord::Base.transaction do
          add_activity_message("Conversations merged: #{@conversations_to_merge.map(&:display_id).join(', ')}")
          duplicate_messages
          
          if @all_contacts.size > 1
            # binding.pry
            
            @all_contacts.each do |contact|
              ConversationContactParticipant.find_or_create_by!(
                conversation_id: @primary_conversation.id,
                contact_id: contact,
                account_id: @primary_conversation.account_id
              )
            end
          end
        end
    end
  
    private
  
    def add_activity_message(content)
        # binding.pry
      @primary_conversation.messages.create!(
        content: content,
        account_id: @primary_conversation.account_id,
        message_type: :activity,
        content_type: :text,
        inbox_id: @primary_conversation.inbox_id,
    )
    end

    def add_merged_message(conversation, content)
      # binding.pry
      conversation.messages.create!(
      content: content,
      account_id: conversation.account_id,
      message_type: :activity,
      content_type: :text,
      inbox_id: conversation.inbox_id,
      )
    end
  
    def duplicate_messages
      @conversations_to_merge.each do |conversation|
        conversation.messages.where.not(message_type: 'activity').each do |message|
            # binding.pry
          ::Messages::MessageBuilder.new(
            message.sender,
            @primary_conversation,
            {
              content: message.content,
              message_type: 'outgoing', 
              private: true
            }
          ).perform
        end
        # binding.pry
        conversation.update!(merged_with_id: @primary_conversation.id);
        add_merged_message( conversation , "Merged into conversation: #{@primary_conversation.display_id}")
      end
    end
  end