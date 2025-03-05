import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn, get } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";

export default class ProcessSelector extends Component {
  @service fabubloxApi;
  @tracked isLoading = false;
  @tracked processes = [];
  @tracked processSvgs = new Map();
  @tracked isDropdownOpen = false;
  @tracked selectedProcess = null;
  @tracked selectedProcessSvg = null;

  constructor() {
    super(...arguments);
    console.log("[ProcessSelector] Component initialized");
    console.log("[ProcessSelector] Initial fieldValue:", this.args.fieldValue);
    this.loadUserProcesses();

    // If we already have a process ID, load its details
    if (this.args.fieldValue) {
      console.log("[ProcessSelector] Found existing fieldValue, loading process details");
      this.loadSelectedProcess(this.extractProcessId(this.args.fieldValue));
    }
  }

  extractProcessId(value) {
    console.log("[ProcessSelector] Extracting process ID from:", value);
    if (!value) {
      console.log("[ProcessSelector] No value provided, returning null");
      return null;
    }

    // If it's a full URL, extract the process ID
    if (value.includes("/")) {
      console.log("[ProcessSelector] Value contains '/', extracting ID from URL");
      const parts = value.split("/");
      const processId = parts[parts.length - 1];
      console.log("[ProcessSelector] Extracted process ID:", processId);
      return processId;
    }

    // Otherwise, assume it's already a process ID
    console.log("[ProcessSelector] Value is already a process ID");
    return value;
  }

  async loadUserProcesses() {
    console.log("[ProcessSelector] Loading user processes");
    this.isLoading = true;
    try {
      console.log("[ProcessSelector] Calling fabubloxApi.fetchUserProcesses()");
      const processes = await this.fabubloxApi.fetchUserProcesses();
      console.log("[ProcessSelector] Received processes:", processes);
      this.processes = processes;

      // Load SVG previews for each process
      console.log("[ProcessSelector] Loading SVG previews for each process");
      for (const process of processes) {
        console.log("[ProcessSelector] Loading SVG for process:", process.processId);
        this.loadProcessSvg(process.processId);
      }
    } catch (error) {
      console.error("[ProcessSelector] Error loading user processes:", error);
      this.isLoading = false;
    } finally {
      console.log("[ProcessSelector] Finished loading user processes");
      this.isLoading = false;
    }
  }

  async loadProcessSvg(processId) {
    console.log("[ProcessSelector] Loading SVG for process ID:", processId);
    try {
      console.log("[ProcessSelector] Calling fabubloxApi.getProcessSvgPreview()");
      const svg = await this.fabubloxApi.getProcessSvgPreview(processId);
      console.log("[ProcessSelector] Received SVG:", svg ? "SVG content received" : "No SVG content");
      this.processSvgs.set(processId, svg);
      // Force a re-render
      console.log("[ProcessSelector] Forcing re-render by creating new Map");
      this.processSvgs = new Map(this.processSvgs);
    } catch (error) {
      console.error("[ProcessSelector] Error loading SVG:", error);
    }
  }

  async loadSelectedProcess(processId) {
    console.log("[ProcessSelector] Loading selected process:", processId);
    if (!processId) {
      console.log("[ProcessSelector] No process ID provided, returning");
      return;
    }

    try {
      console.log("[ProcessSelector] Calling fabubloxApi.fetchProcessById()");
      const process = await this.fabubloxApi.fetchProcessById(processId);
      console.log("[ProcessSelector] Received process:", process);
      if (process) {
        console.log("[ProcessSelector] Setting selectedProcess");
        this.selectedProcess = process;
        console.log("[ProcessSelector] Loading SVG preview");
        const svg = await this.fabubloxApi.getProcessSvgPreview(processId);
        console.log("[ProcessSelector] Setting selectedProcessSvg");
        this.selectedProcessSvg = svg;
      } else {
        console.log("[ProcessSelector] No process found for ID:", processId);
      }
    } catch (error) {
      console.error("[ProcessSelector] Error loading selected process:", error);
    }
  }

  @action
  toggleDropdown() {
    console.log("[ProcessSelector] Toggle dropdown called, current state:", this.isDropdownOpen);
    this.isDropdownOpen = !this.isDropdownOpen;
    console.log("[ProcessSelector] New dropdown state:", this.isDropdownOpen);
  }

  @action
  selectProcess(process) {
    console.log("[ProcessSelector] Process selected:", process);
    this.selectedProcess = process;
    console.log("[ProcessSelector] Setting selectedProcessSvg from processSvgs Map");
    this.selectedProcessSvg = this.processSvgs.get(process.processId);
    console.log("[ProcessSelector] Closing dropdown");
    this.isDropdownOpen = false;

    // Call the parent component's onChangeField action with the process ID
    console.log("[ProcessSelector] Checking if onChangeField callback exists");
    if (this.args.onChangeField) {
      console.log("[ProcessSelector] Calling onChangeField with process ID:", process.processId);
      this.args.onChangeField(process.processId);
    } else {
      console.log("[ProcessSelector] No onChangeField callback provided");
    }
  }

  <template>
    <div class="process-selector">
      {{#if this.isLoading}}
        <div class="loading-spinner-container">Loading...</div>
      {{else}}
        {{#if this.selectedProcess}}
          <div class="selected-process">
            <div class="process-preview">
              {{#if this.selectedProcessSvg}}
                <div class="process-svg" {{htmlSafe this.selectedProcessSvg}}></div>
              {{else}}
                <div class="process-placeholder"></div>
              {{/if}}
            </div>
            <div class="process-info">
              <div class="process-name">{{this.selectedProcess.processName}}</div>
              <DButton
                @action={{this.toggleDropdown}}
                @icon="exchange"
                @label="topic_custom_field.change_process"
                class="change-process-btn"
              />
            </div>
          </div>
        {{else}}
          <DButton
            @action={{this.toggleDropdown}}
            @icon="plus"
            @label="topic_custom_field.add_reference_process"
            class="add-process-btn"
          />
        {{/if}}

        {{#if this.isDropdownOpen}}
          <div class="process-dropdown">
            <div class="dropdown-header">
              <h3>Select a Process</h3>
              <DButton
                @action={{this.toggleDropdown}}
                @icon="times"
                class="close-dropdown-btn"
              />
            </div>
            <div class="process-list">
              {{#if this.processes.length}}
                {{#each this.processes as |process|}}
                  <div class="process-item" {{on "click" (fn this.selectProcess process)}}>
                    <div class="process-item-preview">
                      {{#if (get this.processSvgs process.processId)}}
                        <div class="process-svg" {{htmlSafe (get this.processSvgs process.processId)}}></div>
                      {{else}}
                        <div class="process-placeholder"></div>
                      {{/if}}
                    </div>
                    <div class="process-item-name">{{process.processName}}</div>
                  </div>
                {{/each}}
              {{else}}
                <div class="no-processes">
                  No processes found
                </div>
              {{/if}}
            </div>
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
}