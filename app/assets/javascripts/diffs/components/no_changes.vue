<script>
import { mapGetters } from 'vuex';
import { GlButton, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    changesEmptyStateIllustration: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', [
      'diffCompareDropdownTargetVersions',
      'diffCompareDropdownSourceVersions',
    ]),
    ...mapGetters(['getNoteableData']),
    selectedSourceVersionName() {
      return this.diffCompareDropdownSourceVersions.find(x => x.selected)?.versionName || '';
    },
    selectedTargetVersionName() {
      return this.diffCompareDropdownTargetVersions.find(x => x.selected)?.versionName || '';
    },
  },
};
</script>

<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content svg-250"><img :src="changesEmptyStateIllustration" /></div>
    </div>
    <div class="col-12">
      <div class="text-content text-center">
        <gl-sprintf :message="__('No changes between %{source} and %{target}')">
          <template #source>
            <span
              v-if="
                selectedSourceVersionName == 'latest version' || selectedSourceVersionName == ''
              "
              class="ref-name"
              >{{ getNoteableData.source_branch }}</span
            >
            <span v-else-if="selectedSourceVersionName != 'latest version'" class="ref-name">{{
              selectedSourceVersionName
            }}</span>
          </template>
          <template #target>
            <span v-if="diffCompareDropdownTargetVersions.version_index == -1" class="ref-name">{{
              getNoteableData.target_branch
            }}</span>
            <span
              v-else-if="diffCompareDropdownTargetVersions.version_index != -1"
              class="ref-name"
              >{{ selectedTargetVersionName }}</span
            >
          </template>
        </gl-sprintf>
        <div class="text-center">
          <gl-button :href="getNoteableData.new_blob_path" variant="success" category="primary">{{
            __('Create commit')
          }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
