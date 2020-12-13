import { extractSecurityReportArtifacts } from '~/vue_shared/security_reports/utils';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
  ARCHIVE,
  TRACE,
  METADATA,
} from '~/vue_shared/security_reports/constants';
import {
  securityReportDownloadPathsQueryResponse,
  sastArtifacts,
  secretDetectionArtifacts,
  archiveArtifacts,
  traceArtifacts,
  metadataArtifacts,
} from './mock_data';

describe('extractSecurityReportArtifacts', () => {
  it.each`
    reportTypes                                         | expectedArtifacts
    ${[]}                                               | ${[]}
    ${['foo']}                                          | ${[]}
    ${[REPORT_TYPE_SAST]}                               | ${sastArtifacts}
    ${[REPORT_TYPE_SECRET_DETECTION]}                   | ${secretDetectionArtifacts}
    ${[REPORT_TYPE_SAST, REPORT_TYPE_SECRET_DETECTION]} | ${[...secretDetectionArtifacts, ...sastArtifacts]}
    ${[ARCHIVE]}                                        | ${archiveArtifacts}
    ${[TRACE]}                                          | ${traceArtifacts}
    ${[METADATA]}                                       | ${metadataArtifacts}
  `(
    'returns the expected artifacts given report types $reportTypes',
    ({ reportTypes, expectedArtifacts }) => {
      expect(
        extractSecurityReportArtifacts(reportTypes, securityReportDownloadPathsQueryResponse),
      ).toEqual(expectedArtifacts);
    },
  );
});
