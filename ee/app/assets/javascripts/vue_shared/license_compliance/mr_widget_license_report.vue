<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLink } from '@gitlab/ui';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import ReportItem from '~/reports/components/report_item.vue';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import SetLicenseApprovalModal from 'ee/vue_shared/license_compliance/components/set_approval_status_modal.vue';
import { componentNames } from 'ee/reports/components/issue_body';
import Icon from '~/vue_shared/components/icon.vue';
import ReportSection from '~/reports/components/report_section.vue';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import createStore from './store';

const store = createStore();

export default {
  name: 'MrWidgetLicenses',
  componentNames,
  store,
  components: {
    GlLink,
    ReportItem,
    ReportSection,
    SetLicenseApprovalModal,
    SmartVirtualList,
    Icon,
  },
  mixins: [reportsMixin],
  props: {
    fullReportPath: {
      type: String,
      required: false,
      default: null,
    },
    licenseManagementSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    apiUrl: {
      type: String,
      required: true,
    },
    licensesApiPath: {
      type: String,
      required: false,
      default: '',
    },
    canManageLicenses: {
      type: Boolean,
      required: true,
    },
    reportSectionClass: {
      type: String,
      required: false,
      default: '',
    },
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    securityApprovalsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  typicalReportItemHeight: 26,
  maxShownReportItems: 20,
  computed: {
    ...mapState(LICENSE_MANAGEMENT, ['loadLicenseReportError']),
    ...mapGetters(LICENSE_MANAGEMENT, [
      'licenseReport',
      'isLoading',
      'licenseSummaryText',
      'reportContainsBlacklistedLicense',
      'licenseReportGroups',
    ]),
    hasLicenseReportIssues() {
      const { licenseReport } = this;
      return licenseReport && licenseReport.length > 0;
    },
    licenseReportStatus() {
      return this.checkReportStatus(this.isLoading, this.loadLicenseReportError);
    },
    showActionButtons() {
      return this.licenseManagementSettingsPath !== null || this.fullReportPath !== null;
    },
  },
  watch: {
    licenseReport() {
      this.$emit('updateBadgeCount', this.licenseReport.length);
    },
  },
  mounted() {
    const { apiUrl, canManageLicenses, licensesApiPath } = this;

    this.setAPISettings({
      apiUrlManageLicenses: apiUrl,
      canManageLicenses,
      licensesApiPath,
    });

    this.fetchParsedLicenseReport();
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, ['setAPISettings', 'fetchParsedLicenseReport']),
  },
};
</script>
<template>
  <div>
    <set-license-approval-modal />
    <report-section
      :status="licenseReportStatus"
      :loading-text="licenseSummaryText"
      :error-text="licenseSummaryText"
      :neutral-issues="licenseReport"
      :has-issues="hasLicenseReportIssues"
      :component="$options.componentNames.LicenseIssueBody"
      :class="reportSectionClass"
      :always-open="alwaysOpen"
      class="license-report-widget mr-report"
      data-qa-selector="license_report_widget"
    >
      <template #body>
        <smart-virtual-list
          ref="reportSectionBody"
          :size="$options.typicalReportItemHeight"
          :length="licenseReport.length"
          :remain="$options.maxShownReportItems"
          class="report-block-container"
          wtag="ul"
          wclass="report-block-list my-1"
        >
          <template v-for="(licenseReportGroup, index) in licenseReportGroups">
            <li
              ref="reportHeading"
              :key="licenseReportGroup.name"
              :class="{ 'mt-3': index > 0 }"
              class="mx-1 mb-1"
            >
              <h2 class="h5 m-0">{{ licenseReportGroup.name }}</h2>
              <p class="m-0">{{ licenseReportGroup.description }}</p>
            </li>
            <report-item
              v-for="license in licenseReportGroup.licenses"
              :key="license.name"
              :issue="license"
              :status="license.status"
              :component="$options.componentNames.LicenseIssueBody"
              :show-report-section-status-icon="true"
              class="my-1"
            />
          </template>
        </smart-virtual-list>
      </template>
      <template #success>
        <div class="pr-3">
          {{ licenseSummaryText }}
          <gl-link
            v-if="reportContainsBlacklistedLicense && securityApprovalsHelpPagePath"
            :href="securityApprovalsHelpPagePath"
            class="js-security-approval-help-link"
            target="_blank"
          >
            <icon :size="12" name="question" />
          </gl-link>
        </div>
      </template>
      <div v-if="showActionButtons" slot="actionButtons" class="append-right-default">
        <a
          v-if="licenseManagementSettingsPath"
          :class="{ 'append-right-8': fullReportPath }"
          :href="licenseManagementSettingsPath"
          class="btn btn-default btn-sm js-manage-licenses"
        >
          {{ s__('ciReport|Manage licenses') }}
        </a>
        <a
          v-if="fullReportPath"
          :href="fullReportPath"
          target="_blank"
          class="btn btn-default btn-sm js-full-report"
        >
          {{ s__('ciReport|View full report') }} <icon :size="16" name="external-link" />
        </a>
      </div>
    </report-section>
  </div>
</template>
