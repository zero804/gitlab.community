import { __ } from '~/locale';
import { AvailableSortOptions } from '~/issuable_list/constants';

export const EpicsSortOptions = [
  {
    id: AvailableSortOptions.length + 1,
    title: __('Start date'),
    sortDirection: {
      descending: 'start_date_desc',
      ascending: 'start_date_asc',
    },
  },
  {
    id: AvailableSortOptions.length + 2,
    title: __('Due date'),
    sortDirection: {
      descending: 'end_date_desc',
      ascending: 'end_date_asc',
    },
  },
];

export const FilterTokenOperators = [
  { value: '=', description: __('is'), default: 'true' },
  // { value: '!=', description: __('is not') },
];
