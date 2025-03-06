import Service from "@ember/service";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class FabubloxApi extends Service {
  @service currentUser;

  apiBaseUrl = "https://api.fabublox.com";

  // Fetch processes for the current user
  async fetchUserProcesses() {
    if (!this.currentUser) {
      return [];
    }

    try {
      // Get the user's auth0 ID from Discourse
      const auth0Id = this.currentUser.custom_fields?.auth0_id;

      if (!auth0Id) {
        // eslint-disable-next-line no-console
        console.error("[FabubloxApi] User not authenticated with Auth0");
        return [];
      }

      // Call the Fabublox API to get the user's processes
      const response = await ajax(`${this.apiBaseUrl}/user/processes/${auth0Id}`, {
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
    if (!processId) {
      return null;
    }

    try {
      // Call the Fabublox API to get the process details
      const response = await ajax(`${this.apiBaseUrl}/user/process/${processId}`, {
        type: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      // Map the response to the format expected by the UI
      return {
        processId: response.processId,
        processName: response.processName,
        description: response.desc || "",
        lastUpdatedAt: response.lastUpdatedAt,
        isPrivate: response.isPrivate
      };

    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("[FabubloxApi] Error fetching process by ID:", error);
      popupAjaxError(error);
      return null;
    }
  }

  // Generate SVG preview for a process
  async getProcessSvgPreview(processId) {
    if (!processId) {
      return null;
    }

    try {
      // First, try to get the process details which includes the thumbnail
      const processResponse = await ajax(`${this.apiBaseUrl}/user/process/${processId}`, {
        type: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      // If the process has a thumbnail, use it
      if (processResponse.thumbnail) {
        return processResponse.thumbnail;
      }

      // Otherwise, generate a placeholder SVG
      return `<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <rect width="100" height="100" fill="#f0f0f0" />
        <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="Arial" font-size="14">
          ${processId.substring(0, 8)}
        </text>
      </svg>`;

    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("[FabubloxApi] Error getting SVG preview:", error);
      popupAjaxError(error);

      // Return a placeholder SVG if there's an error
      return `<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <rect width="100" height="100" fill="#f0f0f0" />
        <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="Arial" font-size="14">
          No Preview
        </text>
      </svg>`;
    }
  }
}