import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { extractTokenFromAuth0 } from "../lib/auth";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";

export default class ProcessSelectorModal extends Component {
  @service siteSettings;
  @service currentUser;

  @tracked loading = true;
  @tracked error = null;
  @tracked iframeUrl = null;

  constructor() {
    super(...arguments);
    this.initializeSelector();
  }

  async initializeSelector() {
    try {
      // Get the Auth0 token
      const token = await extractTokenFromAuth0();

      if (!token) {
        this.error = "Authentication failed. Please try again.";
        this.loading = false;
        return;
      }

      // Construct URL with token as a query parameter
      const baseUrl = "https://www.fabublox.com/process-selector";
      const url = new URL(baseUrl);
      url.searchParams.append("token", token);
      url.searchParams.append("origin", window.location.origin);

      this.iframeUrl = url.toString();
      this.loading = false;
    } catch (_) {
      this.error = "Failed to initialize the process selector. Please try again.";
      this.loading = false;
    }
  }

  @action
  handleMessage(event) {
    // Validate the origin
    if (new URL(event.origin).hostname !== "www.fabublox.com") {
      return;
    }

    // Process the message
    if (event.data && event.data.type === "processSelected" && event.data.process) {
      if (this.args.model && this.args.model.onSelect) {
        // Pass the process data to the parent component
        this.args.model.onSelect({
          processUrl: event.data.process.url,
          svgContent: event.data.process.svgContent
        });
      }

      // Close the modal
      this.args.closeModal();
    }
  }

  <template>
    <DModal
      @title="Select a Process"
      @closeModal={{@closeModal}}
    >
      <:body>
        {{#if this.loading}}
          <div class="loading-spinner">
            <div class="spinner"></div>
            <p>Loading process selector...</p>
          </div>
        {{else if this.error}}
          <div class="error-message">
            <p>{{this.error}}</p>
          </div>
        {{else}}
          <div class="iframe-container">
            <iframe
              src={{this.iframeUrl}}
              width="100%"
              height="100%"
              frameborder="0"
              {{on "load" (action (mut this.loading) false)}}
              {{on "message" this.handleMessage}}
            ></iframe>
          </div>
        {{/if}}
      </:body>

      <:footer>
        <DButton
          @action={{@closeModal}}
          @label="Cancel"
        />
      </:footer>
    </DModal>
  </template>
}