<script>
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
// We are forced to use `v-html` untill this gitlab-ui MR is merged: https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/1869
//  then we can re-write this to use gl-breadcrumb

export default {
  components: {
    GlBreadcrumb,
    GlIcon,
  },
  props: {
    crumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    rootRoute() {
      return this.$router.options.routes.find(r => r.meta.root);
    },
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    isLoaded() {
      return this.isRootRoute || this.$store.state.imageDetails?.name;
    },
    allCrumbs() {
      const crumbs = this.crumbs.map(c => {
        return { text: c.innerText, href: c.firstChild.href };
      });
      if (!this.isRootRoute) {
        const crumb = crumbs.pop();
        crumbs.push(
          {
            text: this.rootRoute.meta.nameGenerator(this.$store.state),
            href: this.$router.options.base,
          },
          {
            text: this.$store.state.imageDetails?.name,
            href: crumb.href,
          },
        );
      }
      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="isLoaded" :items="allCrumbs">
    <template #separator>
      <gl-icon name="angle-right" :size="8" />
    </template>
  </gl-breadcrumb>
</template>
