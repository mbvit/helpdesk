FactoryBot.define do
  factory :conversation_escalation do
    conversation { nil }
    team_id { 1 }
    delay_in_seconds { 1 }
    status { 'MyString' }
    scheduled_at { '2025-06-19 16:53:04' }
  end
end
