import { capitalize } from 'lodash';
import {
  securityReportTypeEnumToReportType,
  reportFileTypes,
} from 'ee_else_ce/vue_shared/security_reports/constants';

export const extractSecurityReportArtifacts = (reportTypes, data) => {
  const jobs = data.project?.mergeRequest?.headPipeline?.jobs?.nodes ?? [];

  return jobs.reduce((acc, job) => {
    const artifacts = job.artifacts?.nodes ?? [];

    artifacts.forEach(({ downloadPath, fileType }) => {
      let reportType = securityReportTypeEnumToReportType[fileType];
      if (reportType && reportTypes.includes(reportType)) {
        acc.push({
          name: job.name,
          reportType,
          path: downloadPath,
        });
      }

      reportType = reportFileTypes[fileType];

      if (reportType && reportTypes.includes(reportType)) {
        acc.push({
          name: `${job.name} ${capitalize(reportType)}`,
          reportType,
          path: downloadPath,
        });
      }
    });

    return acc;
  }, []);
};
