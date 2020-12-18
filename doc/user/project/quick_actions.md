---
type: reference
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Quick Actions

> - Introduced in [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26672):
>   once an action is executed, an alert appears when a quick action is successfully applied.
> - In [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/16877) and later, you can use
>   quick actions when updating the description of issues, epics, and merge requests.

Quick actions are textual shortcuts for common actions on issues, epics, merge requests,
and commits that are usually done by clicking buttons or dropdowns in the GitLab UI.
You can enter these commands in the description or in comments of issues, epics, merge requests, and commits.
Each command should be on a separate line in order to be properly detected and executed.

## Quick Actions for issues, merge requests and epics

The following quick actions are applicable to descriptions, discussions and threads in:

- Issues
- Merge requests
- Epics **(PREMIUM)**

| Command                               | Issue | Merge request | Epic | Action                                                                                                                          |
| :------------------------------------ | :---- | :------------ | :--- | :------------------------------------------------------------------------------------------------------------------------------ |
| `/approve`                            |       | ✓             |      | Approve the merge request. **(STARTER)**                                                                                         |
| `/assign @user`                       | ✓     | ✓             |      | Assign one user.                                                                                                                 |
| `/assign @user1 @user2`               | ✓     | ✓             |      | Assign multiple users. **(STARTER)**                                                                                             |
| `/assign me`                          | ✓     | ✓             |      | Assign yourself.                                                                                                                 |
| `/assign_reviewer @user`              |       | ✓             |      | Assign one user as a reviewer.                                                                                                                 |
| `/assign_reviewer @user1 @user2`      |       | ✓             |      | Assign multiple users as reviewers. **(STARTER)**                                                                                             |
| `/assign_reviewer me`                 |       | ✓             |      | Assign yourself as a reviewer.                                                                                                                 |
| `/award :emoji:`                      | ✓     | ✓             | ✓    | Toggle emoji award.                                                                                                              |
| `/child_epic <epic>`                  |       |               | ✓    | Add child epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/-/issues/7330)). **(ULTIMATE)** |
| `/clear_weight`                       | ✓     |               |      | Clear weight. **(STARTER)**                                                                                                      |
| `/clone <path/to/project> [--with_notes]`| ✓     |               |      | Clone the issue to given project, or the current one if no arguments are given ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9421) in GitLab 13.7). Copies as much data as possible as long as the target project contains equivalent labels, milestones, and so on. Does not copy comments or system notes unless `--with_notes` is provided as an argument. |
| `/close`                              | ✓     | ✓             | ✓    | Close.                                                                                                                           |
| `/confidential`                       | ✓     |               |      | Make confidential.                                                                                                               |
| `/copy_metadata <!merge_request>`     | ✓     | ✓             |      | Copy labels and milestone from another merge request in the project.                                                             |
| `/copy_metadata <#issue>`             | ✓     | ✓             |      | Copy labels and milestone from another issue in the project.                                                                     |
| `/create_merge_request <branch name>` | ✓     |               |      | Create a new merge request starting from the current issue.                                                                      |
| `/done`                               | ✓     | ✓             | ✓    | Mark to do as done.                                                                                                              |
| `/draft`                              |       | ✓             |      | Toggle the draft status.                                                                                              |
| `/due <date>`                         | ✓     |               |      | Set due date. Examples of valid `<date>` include `in 2 days`, `this Friday` and `December 31st`.                                 |
| `/duplicate <#issue>`                 | ✓     |               |      | Close this issue and mark as a duplicate of another issue. **(CORE)** Also, mark both as related. **(STARTER)**                                          |
| `/epic <epic>`                        | ✓     |               |      | Add to epic `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic. **(PREMIUM)**  |
| `/estimate <<W>w <DD>d <hh>h <mm>m>`  | ✓     | ✓             |      | Set time estimate. For example, `/estimate 1w 3d 2h 14m`.                                                                        |
| `/iteration *iteration:"iteration name"`     | ✓     |               |      | Set iteration. For example, to set the `Late in July` iteration: `/iteration *iteration:"Late in July"` ([introduced in GitLab 13.1](https://gitlab.com/gitlab-org/gitlab/-/issues/196795)). **(STARTER)** |
| `/label ~label1 ~label2`              | ✓     | ✓             | ✓    | Add one or more labels. Label names can also start without a tilde (`~`), but mixed syntax is not supported.                      |
| `/lock`                               | ✓     | ✓             |      | Lock the discussions.                                                                                                                 |
| `/merge`                              |       | ✓             |      | Merge changes. Depending on the project setting, this may be [when the pipeline succeeds](merge_requests/merge_when_pipeline_succeeds.md), adding to a [Merge Train](../../ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md), etc.  |
| `/milestone %milestone`               | ✓     | ✓             |      | Set milestone.                                                                                                                   |
| `/move <path/to/project>`             | ✓     |               |      | Move this issue to another project.                                                                                              |
| `/parent_epic <epic>`                 |       |               | ✓    | Set parent epic to `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/-/issues/10556)). **(ULTIMATE)** |
| `/promote`                            | ✓     |               |      | Promote issue to epic. **(PREMIUM)**                                                                                            |
| `/publish`                            | ✓     |               |      | Publish issue to an associated [Status Page](../../operations/incident_management/status_page.md) ([Introduced in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30906)) **(ULTIMATE)** |
| `/reassign @user1 @user2`             | ✓     | ✓             |      | Replace current assignees with those specified. **(STARTER)**                                                                                         |
| `/relabel ~label1 ~label2`            | ✓     | ✓             | ✓    | Replace current labels with those specified.                                                                        |
| `/relate #issue1 #issue2`             | ✓     |               |      | Mark issues as related. **(STARTER)**                                                                                            |
| `/remove_child_epic <epic>`           |       |               | ✓    | Remove child epic from `<epic>`. The `<epic>` value should be in the format of `&epic`, `group&epic`, or a URL to an epic ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab/-/issues/7330)). **(ULTIMATE)** |
| `/remove_due_date`                    | ✓     |               |      | Remove due date.                                                                                                                 |
| `/remove_epic`                        | ✓     |               |      | Remove from epic. **(PREMIUM)**                                                                                                  |
| `/remove_estimate`                    | ✓     | ✓             |      | Remove time estimate.                                                                                                            |
| `/remove_iteration`                   | ✓     |               |      | Remove iteration ([introduced in GitLab 13.1](https://gitlab.com/gitlab-org/gitlab/-/issues/196795)) **(STARTER)** |
| `/remove_milestone`                   | ✓     | ✓             |      | Remove milestone.                                                                                                                |
| `/remove_parent_epic`                 |       |               | ✓    | Remove parent epic from epic ([introduced in GitLab 12.1](https://gitlab.com/gitlab-org/gitlab/-/issues/10556)). **(ULTIMATE)**    |
| `/remove_time_spent`                  | ✓     | ✓             |      | Remove time spent.                                                                                                               |
| `/remove_zoom`                        | ✓     |               |      | Remove Zoom meeting from this issue ([introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16609)). |
| `/reopen`                             | ✓     | ✓             | ✓    | Reopen.                                                                                                                          |
| `/shrug <comment>`                    | ✓     | ✓             | ✓    | Append the comment with `¯\＿(ツ)＿/¯`.                                                                                          |
| `/spend <time(-<h>h <mm>m)> <date(<YYYY-MM-DD>)>` | ✓ | ✓     |      | Subtract spent time. Optionally, specify the date that time was spent on. For example, `/spend time(-1h 30m)` or `/spend time(-1h 30m) date(2018-08-26)`. |
| `/spend <time(<h>h <mm>m)> <date(<YYYY-MM-DD>)>` | ✓ | ✓      |      | Add spent time. Optionally, specify the date that time was spent on. For example, `/spend time(1h 30m)` or `/spend time(1h 30m) date(2018-08-26)`. |
| `/submit_review`                      |       | ✓             |      | Submit a pending review ([introduced in GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/issues/8041)). **(PREMIUM)**          |
| `/subscribe`                          | ✓     | ✓             | ✓    | Subscribe to notifications.                                                                                                    |
| `/tableflip <comment>`                | ✓     | ✓             | ✓    | Append the comment with `(╯°□°)╯︵ ┻━┻`.                                                                                        |
| `/target_branch <local branch name>`  |       | ✓             |      | Set target branch.                                                                                                              |
| `/title <new title>`                  | ✓     | ✓             | ✓    | Change title.                                                                                                                  |
| `/todo`                               | ✓     | ✓             | ✓    | Add a to-do item.                                                                                                                   |
| `/unassign @user1 @user2`             | ✓     | ✓             |      | Remove specific assignees. **(STARTER)**                                                                                       |
| `/unassign`                           |       | ✓             |      | Remove all assignees.                                                                                                          |
| `/unassign_reviewer @user1 @user2`    |       | ✓             |      | Remove specific reviewers. **(STARTER)**                                                                                       |
| `/unassign_reviewer`                  |       | ✓             |      | Remove all reviewers.                                                                                                          |
| `/unlabel ~label1 ~label2` or `/remove_label ~label1 ~label2` | ✓     | ✓             | ✓    | Remove specified labels.                                                                         |
| `/unlabel` or `/remove_label` | ✓     | ✓             | ✓    | Remove all labels.                                                                          |
| `/unlock`                             | ✓     | ✓             |      | Unlock the discussions.                                                                                                              |
| `/unsubscribe`                        | ✓     | ✓             | ✓    | Unsubscribe from notifications.                                                                                                |
| `/weight <value>`                     | ✓     |               |      | Set weight. Valid options for `<value>` include `0`, `1`, `2`, and so on. **(STARTER)**                                         |
| `/wip`                                |       | ✓             |      | Toggle the draft status.                                                                                              |
| `/zoom <Zoom URL>`                    | ✓     |               |      | Add Zoom meeting to this issue ([introduced in GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16609)).      |

## Autocomplete characters

Many quick actions require a parameter, for example: username, milestone, and
label. [Autocomplete characters](autocomplete_characters.md) can make it easier
to enter a parameter, compared to selecting items from a list.

## Quick actions parameters

The easiest way to set parameters for quick actions is to use autocomplete. If
you manually enter a parameter, it must be enclosed in double quotation marks
(`"`), unless it contains only these characters:

1. ASCII letters.
1. Numerals (0-9).
1. Underscore (`_`), hyphen (`-`), question mark (`?`), dot (`.`), or ampersand (`&`).

Parameters are also case-sensitive. Autocomplete handles this, and the insertion
of quotation marks, automatically.

## Quick actions for commit messages

The following quick actions are applicable for commit messages:

| Command                 | Action                                    |
| :---------------------- | :---------------------------------------- |
| `/tag v1.2.3 <message>` | Tags this commit with an optional message |

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
