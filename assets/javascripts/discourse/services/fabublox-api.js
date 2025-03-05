import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class FabubloxApi extends Service {
  @service currentUser;

  // Fetch processes for the current user
  async fetchUserProcesses() {
    if (!this.currentUser) {
      return [];
    }

    try {
      // Call our secure Discourse backend endpoint instead of directly accessing auth0_id
      const response = await ajax("/fabublox/user/processes", {
        type: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      // Sort processes by lastUpdatedAt (most recent first)
      const sortedProcesses = response.sort((a, b) => {
        return new Date(b.lastUpdatedAt) - new Date(a.lastUpdatedAt);
      });

      // Map the response to the format expected by the UI
      return sortedProcesses.map(process => ({
        processId: process.processId,
        processName: process.processName,
        description: process.desc || "",
        lastUpdatedAt: process.lastUpdatedAt,
        isPrivate: process.isPrivate
      }));

    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("[FabubloxApi] Error fetching user processes:", error);
      popupAjaxError(error);
      return [];
    }
  }

  // Fetch a single process by ID
  async fetchProcessById(processId) {
    if (!this.currentUser || !processId) {
      return null;
    }

    try {
      // Call our secure Discourse backend endpoint
      const response = await ajax(`/fabublox/process/${processId}`, {
        type: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      return {
        processId: response.processId,
        processName: response.processName,
        description: response.desc || "",
        lastUpdatedAt: response.lastUpdatedAt,
        isPrivate: response.isPrivate,
        // Add other fields as needed
      };
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`[FabubloxApi] Error fetching process ${processId}:`, error);
      popupAjaxError(error);
      return null;
    }
  }

  // Get SVG preview for a process
  async getProcessSvgPreview(processId) {
    if (!this.currentUser || !processId) {
      return null;
    }

    try {
      // Call our secure Discourse backend endpoint
      const response = await ajax(`/fabublox/process/${processId}/svg`, {
        type: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      return response.svgContent;
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`[FabubloxApi] Error fetching SVG for process ${processId}:`, error);
      popupAjaxError(error);
      return null;
    }
  }
}