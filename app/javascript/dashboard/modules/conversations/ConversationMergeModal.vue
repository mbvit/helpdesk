<script>
import { useAlert, useTrack } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { mapGetters } from 'vuex';
import { CONVERSATION_EVENTS } from '../../helper/AnalyticsHelper/events';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'ConversationMergeModal',
  components: { NextButton },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    primaryConversation: {
      type: Object,
      required: true,
    },
  },
  emits: ['close', 'update:show'],
  setup() {
    return { v$: useVuelidate() };
  },
  validations: {
    primaryConversation: {
      required,
    },
    parentConversation: {
      required,
    },
  },
  data() {
    return {
      isSearching: false,
      searchResults: [],
      parentConversation: undefined,
      isLoading: false,
      // --- Added to control the confirmation modal ---
      showConfirmMergeDialog: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'conversations/getUIFlags',
    }),
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    parentConversationTitle() {
      return this.parentConversation
        ? this.parentConversation.meta?.sender?.name
        : '';
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onConversationSearch(query) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = setTimeout(async () => {
        this.isSearching = true;
        this.searchResults = [];
        try {
          const {
            data: { payload },
          } = await ConversationAPI.search({ contact_name: query });
          this.searchResults = payload.filter(
            conversation => conversation.id !== this.primaryConversation.id
          );
        } catch (error) {
          console.error(error);
          useAlert(this.$t('MERGE_CONVERSATIONS.SEARCH.ERROR_MESSAGE'));
        } finally {
          this.isSearching = false;
        }
      }, 300);
    },
    onSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.showConfirmMergeDialog = true;
    },
    async onConfirmMerge() {
      useTrack(CONVERSATION_EVENTS.MERGED_CONVERSATIONS);
      try {
        this.isLoading = true;
        await this.$store.dispatch('mergeConversations', {
          primaryConversationId: this.primaryConversation.id,
          mergeIds: [this.parentConversation.id],
        });
        this.isLoading = false;
        useAlert(this.$t('MERGE_CONVERSATIONS.FORM.SUCCESS_MESSAGE'));
        this.closeConfirmMergeDialog(); // Close confirmation modal
        this.onClose(); // Close main modal
        await this.$store.dispatch(
          'getConversation',
          this.primaryConversation.id
        );
      } catch (error) {
        this.isLoading = false;
        const is422 =
          error?.response?.status === 422 ||
          (typeof error === 'object' && error.message.includes('422'));

        if (is422) {
          useAlert(
            'Cannot merge conversations of different channels for separate contacts'
          );
        } else {
          useAlert(this.$t('MERGE_CONVERSATIONS.FORM.ERROR_MESSAGE'));
        }
      }
    },
    closeConfirmMergeDialog() {
      this.showConfirmMergeDialog = false;
    },
  },
};
</script>

<template>
  <div>
    <woot-modal v-model:show="localShow" :on-close="onClose">
      <woot-modal-header
        :header-title="$t('MERGE_CONVERSATIONS.TITLE')"
        :header-content="$t('MERGE_CONVERSATIONS.DESCRIPTION')"
      />

      <form @submit.prevent="onSubmit">
        <div>
          <div>
            <div
              class="mt-1 multiselect-wrap--medium"
              :class="{ error: v$.parentConversation.$error }"
            >
              <label class="multiselect__label">
                {{ $t('MERGE_CONVERSATIONS.PARENT.TITLE') }}
                <woot-label
                  :title="$t('MERGE_CONVERSATIONS.PARENT.HELP_LABEL')"
                  color-scheme="success"
                  small
                  class="ml-2"
                />
              </label>
              <multiselect
                v-model="parentConversation"
                :options="searchResults"
                label="id"
                track-by="id"
                :internal-search="false"
                :clear-on-select="false"
                :show-labels="false"
                :placeholder="$t('MERGE_CONVERSATIONS.PARENT.PLACEHOLDER')"
                allow-empty
                :loading="isSearching"
                :max-height="150"
                open-direction="top"
                @search-change="onConversationSearch"
              >
                <template #singleLabel="props">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium"
                      >#{{ props.option.id }}</span
                    >
                    <span class="text-sm text-slate-600">
                      {{ props.option?.contact?.name }}
                    </span>
                    <span class="text-xs text-slate-500">
                      {{ props.option.inbox?.name }}
                    </span>
                  </div>
                </template>
                <template #option="props">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium"
                      >#{{ props.option.id }}</span
                    >
                    <span class="text-sm text-slate-600">
                      {{ props.option?.contact?.name }}
                    </span>
                    <span class="text-xs text-slate-500">
                      {{ props.option.inbox?.name }}
                    </span>
                  </div>
                </template>
                <template #noResult>
                  <span>
                    {{ $t('AGENT_MGMT.SEARCH.NO_RESULTS') }}
                  </span>
                </template>
              </multiselect>
              <span v-if="v$.parentConversation.$error" class="message">
                {{ $t('MERGE_CONVERSATIONS.FORM.PARENT_CONVERSATION.ERROR') }}
              </span>
            </div>
          </div>
          <div class="flex multiselect-wrap--medium">
            <div
              class="w-8 relative text-base text-slate-100 dark:text-slate-600 after:content-[''] after:h-12 after:w-0 after:left-4 after:absolute after:border-l after:border-solid after:border-slate-100 after:dark:border-slate-600 before:content-[''] before:h-0 before:w-4 before:left-4 before:top-12 before:absolute before:border-b before:border-solid before:border-slate-100 before:dark:border-slate-600"
            >
              <fluent-icon
                icon="arrow-up"
                class="absolute -top-1 left-2"
                size="17"
              />
            </div>
            <div class="flex flex-col w-full">
              <label class="multiselect__label">
                {{ $t('MERGE_CONVERSATIONS.PRIMARY.TITLE') }}
                <woot-label
                  :title="$t('MERGE_CONVERSATIONS.PRIMARY.HELP_LABEL')"
                  color-scheme="alert"
                  small
                  class="ml-2"
                />
              </label>
              <multiselect
                :model-value="primaryConversation"
                disabled
                :options="[]"
                :show-labels="false"
                label="id"
                track-by="id"
              >
                <template #singleLabel="props">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium"
                      >#{{ props.option.id }}</span
                    >
                    <span class="text-sm text-slate-600">
                      {{ props.option.meta?.sender?.name }}
                    </span>
                    <span class="text-xs text-slate-500">
                      {{ props.option.inbox?.name }}
                    </span>
                  </div>
                </template>
              </multiselect>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-2 mt-6">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('MERGE_CONVERSATIONS.FORM.CANCEL')"
            @click.prevent="onClose"
          />
          <NextButton
            v-if="!isLoading"
            type="submit"
            :label="$t('MERGE_CONVERSATIONS.FORM.SUBMIT')"
          />
          <span v-if="isLoading" class="spinner"></span>
        </div>
      </form>
    </woot-modal>

    <woot-modal
      :show="showConfirmMergeDialog"
      :on-close="closeConfirmMergeDialog"
    >
      <woot-modal-header
        :header-title="$t('MERGE_CONVERSATIONS.CONFIRM.TITLE')"
        header-content="This action is irreversible. Are you sure you want to proceed?"
      />
      <div class="flex justify-end w-full gap-2 mt-6 p-4">
        <NextButton
          faded
          slate
          :label="$t('MERGE_CONVERSATIONS.CONFIRM.CANCEL')"
          @click="closeConfirmMergeDialog"
        />
        <NextButton
          :label="$t('MERGE_CONVERSATIONS.CONFIRM.YES_MERGE')"
          :is-loading="isLoading"
          @click="onConfirmMerge"
        />
      </div>
    </woot-modal>
    </div>
</template>

<style lang="scss" scoped>
/* styles remain the same */
.error .message {
  @apply mt-0;
}

::v-deep {
  .multiselect {
    @apply rounded-md;
  }

  .multiselect--disabled {
    @apply border-0;

    .multiselect__tags {
      @apply border;
    }
  }

  .multiselect__tags {
    @apply h-auto;
  }

  .multiselect__select {
    @apply mt-px mr-1;
  }
}
</style>