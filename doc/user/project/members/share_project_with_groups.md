---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Share Projects with other Groups

You can share projects with other [groups](../../group/index.md). This makes it
possible to add a group of users to a project with a single action.

## Groups as collections of users

Groups are used primarily to [create collections of projects](../../group/index.md), but you can also
take advantage of the fact that groups define collections of _users_, namely the group
members.

## Sharing a project with a group of users

The primary mechanism to give a group of users, say 'Engineering', access to a project,
say 'Project Acme', in GitLab is to make the 'Engineering' group the owner of 'Project
Acme'. But what if 'Project Acme' already belongs to another group, say 'Open Source'?
This is where the group sharing feature can be of use.

To share 'Project Acme' with the 'Engineering' group:

1. For 'Project Acme' use the left navigation menu to go to **Members**.

   ![share project with groups](img/share_project_with_groups_tab_v13_8.png)

1. Select the **Invite group** tab.
1. Add the 'Engineering' group with the maximum access level of your choice.
1. Optionally, select an expiring date.
1. Click **Invite**.
1. After sharing 'Project Acme' with 'Engineering':
   - The group is listed in the **Groups** tab.

     !['Engineering' group is listed in Groups tab](img/project_groups_tab_13_8.png)

   - The project is listed on the group dashboard.

     !['Project Acme' is listed as a shared project for 'Engineering'](img/other_group_sees_shared_project_v13_8.png)

Note that you can only share a project with:

- groups for which you have an explicitly defined membership
- groups that contain a nested subgroup or project for which you have an explicitly defined role

Administrators are able to share projects with any group in the system.

## Maximum access level

In the example above, the maximum access level of 'Developer' for members from 'Engineering' means that users with higher access levels in 'Engineering' ('Maintainer' or 'Owner') only have 'Developer' access to 'Project Acme'.

## Sharing public project with private group

When sharing a public project with a private group, owners and maintainers of the project see the name of the group in the `members` page. Owners also have the possibility to see members of the private group they don't have access to when mentioning them in the issue or merge request.

## Share project with group lock

It is possible to prevent projects in a group from [sharing
a project with another group](../members/share_project_with_groups.md).
This allows for tighter control over project access.

Learn more about [Share with group lock](../../group/index.md#share-with-group-lock).
