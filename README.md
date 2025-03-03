# Discourse Topic Custom Fields with Process Selector

A plugin for Discourse that demonstrates how to add custom fields to a topic, including integration with an external process selector via an iframe.

## Features

- Add a custom field to your Discourse topics
- Process selector modal with iframe integration to Fabublox
- Auth0 token handling for secure authentication
- Display process information in topic headers and topic lists
- Store both process URL and SVG data

## Process Selection Flow

This plugin implements a secure process selection flow between Discourse and Fabublox:

1. User clicks "Browse Processes" button in the composer or topic editor
2. Plugin obtains Auth0 token for the current user
3. Modal is opened with an iframe pointing to Fabublox process selector
4. Token is passed securely via URL parameter
5. Fabublox validates the token and shows only the user's processes
6. When user selects a process, data is sent back to Discourse via postMessage
7. Discourse stores the process URL and SVG in topic custom fields
8. The SVG is displayed in topic headers and lists

## Configuration

Configure the plugin in your Discourse admin settings:

- **topic_custom_field_name**: The name of the custom field for the process URL
- **topic_custom_field_svg_name**: The name of the custom field for storing SVG data
- **topic_custom_field_type**: The type of the custom field

## Security Considerations

- Auth0 tokens are passed securely between trusted domains
- Tokens are validated on both ends
- User identity is verified when process data is sent back to Discourse
- postMessage communication is restricted to specific domains
- Communication is ephemeral and only during process selection

## Integration with Fabublox

The Fabublox process selector page should:

1. Accept an Auth0 token via URL parameter
2. Validate the token with Auth0
3. Extract user sub (ID) from the token
4. Display only processes belonging to that user
5. When a process is selected, send data back via postMessage:
   ```js
   window.parent.postMessage({
     type: "process-selected",
     data: {
       processUrl: "https://www.fabublox.com/process-editor/[PROCESS-ID]",
       svgContent: "<svg>...</svg>",
       userSub: "[USER-SUB-FROM-TOKEN]"
     }
   }, "https://your-discourse-domain.com");
   ```

## License

MIT