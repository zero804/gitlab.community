import { capitalize } from 'lodash';
import {
  securityReportTypeEnumToReportType,
  reportFileTypes,
} from 'ee_else_ce/vue_shared/security_reports/constants';

const addReportTypeIfExists = (acc, reportTypes, reportType, getName, downloadPath) => {
  if (reportTypes && reportTypes.includes(reportType)) {
    acc.push({
      reportType,
      name: getName(reportType),
      path: downloadPath,
    });
  }
};

export const extractSecurityReportArtifacts = (reportTypes, data) => {
  const jobs = data.project?.mergeRequest?.headPipeline?.jobs?.nodes ?? [];

  return jobs.reduce((acc, job) => {
    const artifacts = job.artifacts?.nodes ?? [];

    artifacts.forEach(({ downloadPath, fileType }) => {
      addReportTypeIfExists(
        acc,
        reportTypes,
        securityReportTypeEnumToReportType[fileType],
        () => job.name,
        downloadPath,
      );

      addReportTypeIfExists(
        acc,
        reportTypes,
        reportFileTypes[fileType],
        reportType => `${job.name} ${capitalize(reportType)}`,
        downloadPath,
      );
    });

    return acc;
  }, []);
};
