<script>
import { __ } from '~/locale';
import LinkedPipeline from './linked_pipeline.vue';
import { UPSTREAM, DOWNSTREAM } from './constants';

export default {
  name: 'LinkedPipelinesColumn',
  components: {
    LinkedPipeline,
    PipelineGraph: () => import('./graph_component.vue'),
  },
  inject: {
    mediator: {
      default: () => ({})
    }
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    columnClass() {
      const positionValues = {
        right: 'gl-ml-11',
        left: 'gl-mr-7',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    graphPosition() {
      return this.isUpstream ? 'left' : 'right';
    },
    // Refactor string match when BE returns Upstream/Downstream indicators
    isUpstream() {
      return this.type === UPSTREAM;
    },
  },
  methods: {
    onPipelineClick(downstreamNode, pipeline, index) {
      this.$emit('linkedPipelineClick', pipeline, index, downstreamNode);
    },
    onDownstreamHovered(jobName) {
      this.$emit('downstreamHovered', jobName);
    },
    onPipelineExpandToggle(jobName, expanded) {
      // Highlighting only applies to downstream pipelines
      if (this.isUpstream) {
        return;
      }

      this.$emit('pipelineExpandToggle', jobName, expanded);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <div :class="columnClass" class="stage-column linked-pipelines-column">
      <div class="stage-name linked-pipelines-column-title">{{ columnTitle }}</div>
      <div v-if="isUpstream" class="cross-project-triangle"></div>
      <ul>
        <li
          v-for="(pipeline, index) in linkedPipelines"
          class="gl-display-flex"
          :class="{'gl-flex-direction-row-reverse': isUpstream}"
        >
          <linked-pipeline
            :key="pipeline.id"
            :class="{
              active: pipeline.isExpanded,
              'left-connector': pipeline.isExpanded && graphPosition === 'left',
            }"
            :pipeline="pipeline"
            :column-title="columnTitle"
            :project-id="projectId"
            :type="type"
            @pipelineClicked="onPipelineClick($event, pipeline, index)"
            @downstreamHovered="onDownstreamHovered"
            @pipelineExpandToggle="onPipelineExpandToggle"
          />
          <div v-if="pipeline.isExpanded" class="gl-display-inline-block gl-px-2 gl-mt-n6">
            <pipeline-graph
              v-if="pipeline.isExpanded"
              :type="type"
              class="d-inline-block"
              :pipeline="pipeline"
              :is-linked-pipeline="true"
              :is-loading="pipeline.isLoading"
            />
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
