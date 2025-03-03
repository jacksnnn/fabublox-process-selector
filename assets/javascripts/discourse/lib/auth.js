/**
 * Extracts Auth0 token for use in the Fabublox iframe communication
 * @returns {Promise<string>} The Auth0 token
 */
export async function extractToken() {
  return new Promise((resolve, reject) => {
    // In a real implementation, you would get this from your Auth0 integration
    // This is a placeholder for how you would extract the token

    // Option 1: Use existing Auth0 plugin if available
    try {
      const auth0 = requirejs("discourse/plugins/discourse-auth0/api").getAuth0Instance();
      if (auth0 && auth0.getTokenSilently) {
        auth0.getTokenSilently().then(token => {
          resolve(token);
        }).catch(error => {
          reject(new Error("Failed to get Auth0 token: " + error.message));
        });
        return;
      }
    } catch (_) {
      // Auth0 plugin not available, continue to fallback
    }

    // Option 2: Request token from server
    fetch("/auth/auth0/token")
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("Failed to get token from server");
      })
      .then(data => {
        resolve(data.token);
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
  } catch (_) {
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