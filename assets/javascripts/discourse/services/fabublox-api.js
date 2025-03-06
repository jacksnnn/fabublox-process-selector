import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class FabubloxApi extends Service {
  @service currentUser;
  @service siteSettings;

  get apiBaseUrl() {
    return this.siteSettings.fabublox_api_base_url;
  }

  // Get the Auth0 token for the current user
  async getAuth0Token() {
    try {
      const result = await ajax("/fabublox/current_user_token");
      return result.token;
    } catch (error) {
      this._logError("Error fetching Auth0 token:", error);
      return null;
    }
  }

  // Make an authenticated API request
  async authenticatedRequest(endpoint, params = {}) {
    try {
      this._logWarning(`Making authenticated request to: ${endpoint}`);

      // Make sure the endpoint is properly formatted
      const formattedEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

      const data = {
        endpoint: formattedEndpoint,
        ...params
      };

      const result = await ajax("/fabublox/authenticated_request", {
        type: "POST",
        data
      });

      return result;
    } catch (error) {
      this._logError(`Error making authenticated request to ${endpoint}:`, error);
      popupAjaxError(error);
      return null;
    }
  }

  // Fetch processes for the current user
  async fetchUserProcesses() {
    try {
      // First try to get the user's Auth0 ID from their profile
      if (this.currentUser) {
        // Try to make an authenticated request to get the user's processes
        const processes = await this.authenticatedRequest("processes/user");
        if (processes) {
          return processes;
        }
      }

      // Fallback to the old method if authenticated request fails
      const auth0Id = this.currentUser?.auth0_id;
      if (!auth0Id) {
        this._logWarning("No Auth0 ID found for user");
        return [];
      }

      const response = await ajax(`/fabublox/user_processes/${encodeURIComponent(auth0Id)}`);
      return response || [];
    } catch (error) {
      this._logError("Error fetching user processes:", error);
      popupAjaxError(error);
      return [];
    }
  }

  // Fetch a single process by ID
  async fetchProcessById(processId) {
    if (!processId) {
      this._logWarning("No process ID provided");
      return null;
    }

    try {
      // Try authenticated request first
      const process = await this.authenticatedRequest(`processes/${processId}`);
      if (process) {
        return process;
      }

      // Fallback to unauthenticated request
      const response = await ajax(`/fabublox/process/${processId}`);
      return response;
    } catch (error) {
      this._logError(`Error fetching process ${processId}:`, error);
      popupAjaxError(error);
      return null;
    }
  }

  // Generate SVG preview for a process
  async getProcessSvgPreview(processId) {
    if (!processId) {
      this._logWarning("No process ID provided for SVG preview");
      return null;
    }

    try {
      // Try authenticated request first
      const svg = await this.authenticatedRequest(`processes/${processId}/svg`);
      if (svg) {
        return svg;
      }

      // Fallback to unauthenticated request
      const response = await ajax(`/fabublox/process_svg/${processId}`);
      return response;
    } catch (error) {
      this._logError(`Error fetching SVG for process ${processId}:`, error);
      return null;
    }
  }

  // Helper methods for logging
  _logError(message, error) {
    // eslint-disable-next-line no-console
    console.error(`[FabubloxApi] ${message}`, error);
  }

  _logWarning(message) {
    // eslint-disable-next-line no-console
    console.warn(`[FabubloxApi] ${message}`);
  }
}