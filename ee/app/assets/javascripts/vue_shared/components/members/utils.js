import { __ } from '~/locale';
import { generateBadges as CEGenerateBadges } from '~/vue_shared/components/members/utils';

export const generateBadges = (member, isCurrentUser) => [
  ...CEGenerateBadges(member, isCurrentUser),
  {
    show: member.usingLicense,
    text: __('Is using seat'),
    variant: 'neutral',
  },
  {
    show: member.groupSso,
    text: __('SAML'),
    variant: 'info',
  },
  {
    show: member.groupManagedAccount,
    text: __('Managed Account'),
    variant: 'info',
  },
];