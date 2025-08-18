class Conversations::ConversationMergeService
    def initialize(account:, primary_conversation_id:, merge_ids:)
      @account = account
      @primary_conversation = find_conversation!(primary_conversation_id)
      @merge_ids = merge_ids.map(&:to_i) - [@primary_conversation.id]
      @conversations_to_merge = find_conversations!(@merge_ids)
    end
   
    def perform
      # binding.pry
      validate_contact_consistency!
      merge_conversations
      @primary_conversation
    end

    private

    def find_conversation!(id)
      @account.conversations.find(id)
    end

    def find_conversations!(ids)
      @account.conversations.where(id: ids)
    end

    def validate_contact_consistency!
      @all_contacts = (@conversations_to_merge.pluck(:contact_id) + [@primary_conversation.contact_id]).uniq
      if @all_contacts.size > 1 && !same_channel?
        raise StandardError, "Cannot merge conversations of different contacts" if @all_contacts.size > 1
      end
    end

    def same_channel?
      # binding.pry
      all_channels = (@conversations_to_merge.pluck(:inbox_id) + [@primary_conversation.inbox_id])
      inboxes = Inbox.where(id: all_channels.uniq)  # filter the array to remove duplicate entry 

      channels = inboxes.map(&:channel_type).uniq # filter the array to remove duplicate entry 
      channels.size == 1 # if a
    end

    def merge_conversations
      ::Conversations::ConversationMergeHandler.new(@primary_conversation, @conversations_to_merge, @all_contacts).perform
    end
end