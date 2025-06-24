<script setup>
import { formatDistanceToNow, format } from 'date-fns';

const props = defineProps({
  escalations: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <div
    class="absolute z-50 w-80 max-h-96 overflow-auto shadow bg-white dark:bg-slate-800 border border-n-strong rounded-xl px-5 py-4 flex flex-col gap-4 mt-4"
  >
    <span class="text-sm font-semibold text-n-slate-12">
      Escalation Levels
    </span>

    <div
      v-for="escalation in escalations"
      :key="escalation.id"
      class="flex flex-col border-l-2 pl-3 ml-1"
      :class="{
        'border-n-slate-400': escalation.status === 'completed',
        'border-n-amber-10': escalation.status === 'running',
        'border-n-slate-200': escalation.status === 'paused',
      }"
    >
      <div class="flex justify-between items-center">
        <span class="text-sm font-medium text-n-slate-12">
          {{ escalation.team_name }}
        </span>
        <span
          class="text-xs font-semibold uppercase"
          :class="{
            'text-green-600': escalation.status === 'completed',
            'text-amber-600': escalation.status === 'running',
            'text-slate-400': escalation.status === 'paused',
          }"
        >
          {{ escalation.status }}
        </span>
      </div>
      <span class="text-xs text-n-slate-11">
        {{ format(new Date(escalation.scheduled_at), 'PPpp') }}
        ({{ formatDistanceToNow(new Date(escalation.scheduled_at), { addSuffix: true }) }})
      </span>
    </div>
  </div>
</template>

<style scoped>
/* Optional scrollbar styling */
::-webkit-scrollbar {
  width: 6px;
}
::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 4px;
}
</style>
