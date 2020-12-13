import { invert } from 'lodash';

export const FEEDBACK_TYPE_DISMISSAL = 'dismissal';
export const FEEDBACK_TYPE_ISSUE = 'issue';
export const FEEDBACK_TYPE_MERGE_REQUEST = 'merge_request';

/**
 * Security artifact file types
 */
export const ARCHIVE = 'ARCHIVE';
export const TRACE = 'TRACE';
export const METADATA = 'METADATA';

export const reportFileTypes = {
  ARCHIVE,
  TRACE,
  METADATA,
};

/**
 * Security scan report types, as provided by the backend.
 */
export const REPORT_TYPE_SAST = 'sast';
export const REPORT_TYPE_SECRET_DETECTION = 'secret_detection';

/**
 * SecurityReportTypeEnum values for use with GraphQL.
 *
 * These should correspond to the lowercase security scan report types.
 */
export const SECURITY_REPORT_TYPE_ENUM_SAST = 'SAST';
export const SECURITY_REPORT_TYPE_ENUM_SECRET_DETECTION = 'SECRET_DETECTION';

/**
 * A mapping from security scan report types to SecurityReportTypeEnum values.
 */
export const reportTypeToSecurityReportTypeEnum = {
  [REPORT_TYPE_SAST]: SECURITY_REPORT_TYPE_ENUM_SAST,
  [REPORT_TYPE_SECRET_DETECTION]: SECURITY_REPORT_TYPE_ENUM_SECRET_DETECTION,
};

/**
 * A mapping from SecurityReportTypeEnum values to security scan report types.
 */
export const securityReportTypeEnumToReportType = invert(reportTypeToSecurityReportTypeEnum);
