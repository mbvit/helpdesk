<script>
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  data() {
    return {
    thresholdTime: null,
    thresholdUnit: 'Minutes',
    time: 0,
  };
},
  components: {
    AutomationActionTeamMessageInput,
    AutomationActionFileInput,
    WootMessageEditor,
    NextButton,
  },
  props: {
    modelValue: {
      type: Object,
      default: () => null,
    },
    actionTypes: {
      type: Array,
      default: () => [],
    },
    dropdownValues: {
      type: Array,
      default: () => [],
    },
    errorMessage: {
      type: String,
      default: '',
    },
    showActionInput: {
      type: Boolean,
      default: true,
    },
    initialFileName: {
      type: String,
      default: '',
    },
    isMacro: {
      type: Boolean,
      default: false,
    },
    selectedResponse: {
      type: Object,
      default: () => null,
    },
    index: {
      type: Number,
      default: 0,
    },
  },
  mounted() {
    if (this.modelValue?.action_name === 'ticket_escalation') {
       const updatedPayload = { ...this.modelValue };

      if (Array.isArray(updatedPayload.action_params)) {
        // const thresholdTime = this.selectedResponse.actions[0].action_params[1];
        // const thresholdUnit = this.selectedResponse.actions[0].action_params[2];

        updatedPayload.action_params = updatedPayload.action_params.map((param, idx) => ({
          ...param,
          thresholdTime : this.selectedResponse.action_params[1],
          thresholdUnit : this.selectedResponse.action_params[2],
        }));
      }

      this.$emit('update:modelValue', updatedPayload);
    }
  },
  emits: ['update:modelValue', 'input', 'removeAction', 'resetAction'],
  computed: {
    action_name: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_name;
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, action_name: value });
        this.$emit('input', { ...payload, action_name: value });
      },
    },
    action_params: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_params;
      },
      set(value) {
        const payload = this.modelValue || {};

        value = {...value, thresholdTime: this.thresholdTime, thresholdUnit: payload.action_params[0]?.thresholdUnit || this.thresholdUnit};

        
        this.$emit('update:modelValue', { ...payload, action_params: {...payload.action_params, ...value} });
        this.$emit('input', { ...payload, action_params: {...payload.action_params, ...value} });
      },
    },
    inputType() {
      return this.actionTypes.find(action => action.key === this.action_name)
        .inputType;
    },
    actionInputStyles() {
      return {
        'has-error': this.errorMessage,
        'is-a-macro': this.isMacro,
      };
    },
    castMessageVmodel: {
      get() {
        if (Array.isArray(this.action_params)) {
          return this.action_params[this.inde];
        }
        return this.action_params;
      },
      set(value) {
        this.action_params = value;
      },
    },
    thresholdTime: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_params?.thresholdTime || this.modelValue.action_params[0]?.thresholdTime  || null;
      },
      set(value) {
        if (!this.modelValue) return;

        const payload = this.modelValue || {};
        const actionParams = payload.action_params;

        let updatedActionParams;

        if (Array.isArray(actionParams)) {
          // Case: array of objects — update first object in array
          updatedActionParams = [
            {
              ...actionParams[0],
              thresholdTime: value,
            },
            // ...actionParams.slice(1),
          ];
        } else {
          // Case: object — update directly
          updatedActionParams = {
            ...actionParams,
            thresholdTime: value,
          };
        }

        const updatedPayload = {
          ...payload,
          action_params: updatedActionParams,
        };

        this.$emit('update:modelValue', updatedPayload);
        this.$emit('input', updatedPayload); // Vue 2 compatibility
      },
    },

    thresholdUnit: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_params?.thresholdUnit || this.modelValue.action_params[0]?.thresholdUnit || null;
      },
      set(value) {
        if (!this.modelValue) return;

        const payload = this.modelValue || {};
        const actionParams = payload.action_params;

        let updatedActionParams;

        if (Array.isArray(actionParams)) {
          // Case: array of objects — update first object in array
          updatedActionParams = [
            {
              ...actionParams[0],
              thresholdUnit: value,
            },
            // ...actionParams.slice(1),
          ];
        } else {
          // Case: object — update directly
          updatedActionParams = {
            ...actionParams,
            thresholdUnit: value,
          };
        }

        const updatedPayload = {
          ...payload,
          action_params: updatedActionParams,
        };

        this.$emit('update:modelValue', updatedPayload);
        this.$emit('input', updatedPayload); // Vue 2 compatibility
      },
    },
  },
  watch: {
  action_params: {
    immediate: true,
    handler(val) {
      if (this.modelValue?.action_name === 'ticket_escalation') {
        this.thresholdTime = val?.threshold || null;
        this.thresholdUnit = val?.threshold_unit || 'Minutes';
      }
    },
  },
},
  methods: {
  removeAction() {
    this.$emit('removeAction');
  },
  resetAction() {
    this.$emit('resetAction');
  },
  onThresholdTimeChange() {
    if (this.thresholdTime === null || this.thresholdTime === 0) return null;
      const unitsToSeconds = { Minutes: 60, Hours: 3600, Days: 86400 };
      this.time = Number(this.thresholdTime * (unitsToSeconds[this.thresholdUnit] || 1));
    this.action_params = {
      ...this.action_params,
      threshold: this.thresholdTime,
      time: this.time,
    };
  },
  onThresholdUnitChange() {
      if (this.thresholdTime === null || this.thresholdTime === 0) return null;
      const unitsToSeconds = { Minutes: 60, Hours: 3600, Days: 86400 };
      this.time = Number(this.thresholdTime * (unitsToSeconds[this.thresholdUnit] || 1));
    this.action_params = {
      ...this.action_params,
      threshold_unit: this.thresholdUnit,
      time: this.time,
    };
  },
  },
};
</script>

<template>
  <div class="filter" :class="actionInputStyles">
    <div class="filter-inputs">
      <select
        v-model="action_name"
        class="action__question"
        :class="{ 'full-width': !showActionInput ,'flex-[0.8]':modelValue.action_name === 'ticket_escalation' }"
        @change="resetAction()"
      >
        <option
          v-for="attribute in actionTypes"
          :key="attribute.key"
          :value="attribute.key"
        >
          {{ attribute.label }}
        </option>
      </select>
      <div v-if="showActionInput" class="filter__answer--wrap flex-1">
        <div v-if="inputType" class="w-full">
          <div
            v-if="inputType === 'search_select'"
            :class="modelValue.action_name === 'ticket_escalation' ? 'board_pipeline_select_wrap multiselect-wrap--small' : 'multiselect-wrap--small'"
          >
            <multiselect
              v-model="action_params"
              track-by="id"
              label="name"
              :placeholder="$t('FORMS.MULTISELECT.SELECT')"
              selected-label
              select-label="select"
              deselect-label=""
              :max-height="160"
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
            <div
            v-if="modelValue.action_name === 'ticket_escalation'"
            class="multiselect-wrap--small flex items-center gap-2 w-full ml-2"
          >
            <!-- Time Input -->
            <input
              type="number"
              v-model="thresholdTime"
              class="border border-gray-300 rounded-lg px-2 py-1 text-sm w-20 flex-1"
              placeholder="Select Time"
            />

            <!-- Unit Dropdown -->
            <select
              v-model="thresholdUnit"
              class="border border-gray-300 rounded-lg px-2 py-1 text-sm w-24 flex-[0.5]"
            >
              <option value="Minutes">Minutes</option>
              <option value="Hours">Hours</option>
              <option value="Days">Days</option>
            </select>
          </div>
          </div>
          <div
            v-else-if="inputType === 'multi_select'"
            class="multiselect-wrap--small"
          >
            <multiselect
              v-model="action_params"
              track-by="id"
              label="name"
              :placeholder="$t('FORMS.MULTISELECT.SELECT')"
              multiple
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              deselect-label=""
              :max-height="160"
              :options="dropdownValues"
              :allow-empty="false"
              :option-height="104"
            />
          </div>
          <input
            v-else-if="inputType === 'email'"
            v-model="action_params"
            type="email"
            class="answer--text-input"
            :placeholder="$t('AUTOMATION.ACTION.EMAIL_INPUT_PLACEHOLDER')"
          />
          <input
            v-else-if="inputType === 'url'"
            v-model="action_params"
            type="url"
            class="answer--text-input"
            :placeholder="$t('AUTOMATION.ACTION.URL_INPUT_PLACEHOLDER')"
          />
          <AutomationActionFileInput
            v-if="inputType === 'attachment'"
            v-model="action_params"
            :initial-file-name="initialFileName"
          />
        </div>
      </div>
      <NextButton
        v-if="!isMacro"
        icon="i-lucide-x"
        slate
        ghost
        class="flex-shrink-0"
        @click="removeAction"
      />
    </div>
    <AutomationActionTeamMessageInput
      v-if="inputType === 'team_message'"
      v-model="action_params"
      :teams="dropdownValues"
    />
    <WootMessageEditor
      v-if="inputType === 'textarea'"
      v-model="castMessageVmodel"
      rows="4"
      enable-variables
      :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
      class="action-message"
    />
    <p v-if="errorMessage" class="filter-error">
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.filter {
  @apply bg-n-background p-2 border border-solid border-n-strong dark:border-n-strong rounded-lg mb-2;

  &.is-a-macro {
    @apply mb-0 bg-n-background dark:bg-n-solid-1 p-0 border-0 rounded-none;
  }
}

.no-margin-bottom {
  @apply mb-0;
}

.filter.has-error {
  @apply bg-n-ruby-8/20 border-n-ruby-5 dark:border-n-ruby-5;

  &.is-a-macro {
    @apply bg-transparent;
  }
}

.filter-inputs {
  @apply flex gap-1;
}

.filter-error {
  @apply text-n-ruby-9 dark:text-n-ruby-9 block my-1 mx-0;
}

.action__question,
.filter__operator {
  @apply mb-0 mr-1;
}

.action__question {
  @apply max-w-[50%];
}

.action__question.full-width {
  @apply max-w-full;
}

.filter__answer--wrap {
  @apply max-w-[50%] flex-grow mr-1 flex w-full items-center justify-start;

  input {
    @apply mb-0;
  }
}
.filter__answer {
  &.answer--text-input {
    @apply mb-0;
  }
}

.filter__join-operator-wrap {
  @apply relative z-20 m-0;
}

.filter__join-operator {
  @apply flex items-center justify-center relative my-2.5 mx-0;

  .operator__line {
    @apply absolute w-full border-b border-solid border-slate-75 dark:border-slate-600;
  }

  .operator__select {
    margin-bottom: var(--space-zero) !important;
    @apply relative w-auto;
  }
}

.multiselect {
  @apply mb-0;
}
.action-message {
  @apply mt-2 mx-0 mb-0;
}
.board_pipeline_select_wrap{
  display: flex;
  flex-direction: row;
 
  .multiselect__tags{
    width: 200px;
  }
}
// Prosemirror does not have a native way of hiding the menu bar, hence
::v-deep .ProseMirror-menubar {
  @apply hidden;
}
</style>
