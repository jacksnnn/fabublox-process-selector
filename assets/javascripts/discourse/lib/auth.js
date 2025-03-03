/**
 * Extracts Auth0 token for use in the Fabublox iframe communication
 * @returns {Promise<string>} The Auth0 token
 */
export async function extractToken() {
  return new Promise((resolve, reject) => {
    // Try different methods to get the auth token

    // Option 1: Try to get the token from the session data
    try {
      const session = window.localStorage.getItem("discourse_oauth2_basic");
      if (session) {
        const sessionData = JSON.parse(session);
        if (sessionData && sessionData.token) {
          resolve(sessionData.token);
          return;
        }
      }
    } catch (e) {
      void e; // Explicitly ignore error
      // Unable to get token from session storage, continue to other methods
    }

    // Option 2: Try to get token from discourse_oauth2_user_token cookie
    try {
      const tokenCookie = document.cookie
        .split("; ")
        .find(row => row.startsWith("discourse_oauth2_user_token="));

      if (tokenCookie) {
        const token = tokenCookie.split("=")[1];
        if (token) {
          resolve(token);
          return;
        }
      }
    } catch (e) {
      void e; // Explicitly ignore error
      // Unable to get token from cookie, continue to other methods
    }

    // Option 3: Request a new token from the server
    fetch("/session/current.json")
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Failed to get current session data");
      })
      .then(data => {
        if (data && data.current_user && data.current_user.oauth2_user_info) {
          resolve(data.current_user.oauth2_user_info.provider_token || null);
          return;
        }

        // If we can't get the token from the user info, try to get it from the OAuth2 plugin
        return fetch("/oauth2/token.json");
      })
      .then(response => {
        if (response && response.ok) {
          return response.json();
        }
        throw new Error("Failed to get token from OAuth2 endpoint");
      })
      .then(data => {
        if (data && data.token) {
          resolve(data.token);
        } else {
          reject(new Error("Token not found in response"));
        }
      })
      .catch(error => {
        reject(new Error("Failed to get authentication token: " + error.message));
      });
  });
}

/**
 * Extracts token from Auth0 for Fabublox process selector
 * This is a wrapper around extractToken that provides specific functionality
 * for the process selector modal
 * @returns {Promise<string>} The Auth0 token
 */
export async function extractTokenFromAuth0() {
  try {
    return await extractToken();
  } catch (e) {
    void e; // Explicitly ignore error
    return null;
  }
}

/**
 * Validates a message received from the Fabublox iframe
 * @param {Object} message - The message received from postMessage
 * @param {string} expectedSub - The user sub to validate against
 * @returns {boolean} Whether the message is valid
 */
export function validateMessage(message, expectedSub) {
  // In a real implementation, you would validate:
  // 1. The user sub in the message matches the expected sub
  // 2. Any other security checks needed

  if (!message || !message.data || !message.data.userSub) {
    return false;
  }

  return message.data.userSub === expectedSub;
}