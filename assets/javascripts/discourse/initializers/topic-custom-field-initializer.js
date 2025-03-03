import { withPluginApi } from "discourse/lib/plugin-api";
import { service } from "@ember/service";

export default {
  name: "topic-custom-field-initializer",
  initialize(container) {
    // Takes the site settings from the container and gets the topic custom field name
    const siteSettings = container.lookup("service:site-settings");
    const fieldName = siteSettings.topic_custom_field_name;
    const svgFieldName = siteSettings.topic_custom_field_svg_name;

    withPluginApi("1.37.3", (api) => {
      /*
       * type:        step
       * number:      6 & 7
       * title:       Save and Edit field via Composer
       * description: Send your field along with the post and topic data saved
       *              by the user when creating a new topic, saving a draft, or
       *              editing the first post of an existing topic.
       * references:  discourse/app/lib/plugin-api.js,
       *              discourse/app/models/composer.js
       */
      api.serializeOnCreate(fieldName);
      api.serializeToDraft(fieldName);
      api.serializeToTopic(fieldName, `topic.${fieldName}`);

      // Also serialize the SVG field
      api.serializeOnCreate(svgFieldName);
      api.serializeToDraft(svgFieldName);
      api.serializeToTopic(svgFieldName, `topic.${svgFieldName}`);

      /* For step 8 see connectors/topic-title/topic-custom-field-topic-title.js */

      /*
       * type:        step
       * number:      9 & 10
       * title:       Display in topic list
       * description: The topic list customization is now handled by the Glimmer component
       *              in connectors/topic-list-after-title/topic-custom-field-topic-list-after-title.gjs
       *              and components/topic-list-custom-field.gjs
       */

      // Register the custom field for storing process SVG
      api.registerTopicFooterButton({
        id: "process-selector",
        icon: "layer-group",
        title: "topic_custom_field.select_process",
        action() {
          const modal = container.lookup("service:modal");
          import("../components/process-selector-modal").then(({ default: ProcessSelectorModal }) => {
            modal.show(ProcessSelectorModal, {
              model: {
                onSelect: (processData) => {
                  // Update the topic with the selected process
                  const currentTopic = this.get("topic");
                  if (currentTopic) {
                    currentTopic.set(fieldName, processData.processUrl);
                    if (processData.svgContent) {
                      currentTopic.set(svgFieldName, processData.svgContent);
                    }

                    // Save the changes
                    currentTopic.save().catch((error) => {
                      console.error("Error saving topic with process data:", error);
                    });
                  }
                }
              }
            });
          });
        },
        displayed() {
          // Only show for topic creators and staff
          const currentUser = container.lookup("service:current-user");
          const topic = this.get("topic");
          return currentUser &&
                 topic &&
                 (currentUser.id === topic.user_id || currentUser.staff);
        }
      });
    });
  },
};
