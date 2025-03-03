import Component from "@glimmer/component";
import { inject as controller } from "@ember/controller";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";

/*
 * type:        step
 * number:      8
 * title:       Display your field value in the topic
 * description: Display the value of your custom topic field below the
 *              title in the topic
 *              list.
 */

export default class TopicCustomFieldTopicTitle extends Component {
  @service siteSettings;
  @service store;
  @controller topic;
  @alias("siteSettings.topic_custom_field_name") fieldName;
  @alias("siteSettings.topic_custom_field_svg_name") fieldSvgName;

  get fieldValue() {
    return this.topic?.model?.[this.fieldName];
  }

  get svgContent() {
    // Get the custom SVG content if it exists
    const svgContent = this.topic?.model?.[this.fieldSvgName];

    // If we have custom SVG content, return it as HTML safe
    if (svgContent) {
      return htmlSafe(svgContent);
    }

    // Otherwise return the default SVG (could be moved to a separate template)
    return null;
  }

  isValidProcessId(str) {
    // UUID format validation regex
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/?$/i;
    return uuidRegex.test(str);
  }

  get fieldUrl() {
    if (!this.fieldValue) {
      return null;
    }

    // If it's already a valid process ID, use it directly
    if (this.isValidProcessId(this.fieldValue)) {
      return `https://www.fabublox.com/process-editor/${this.fieldValue}`;
    }

    // If it's a full URL, extract and validate the process ID
    const parts = this.fieldValue.split("/");
    const lastPart = parts[parts.length - 1];

    if (this.isValidProcessId(lastPart)) {
      return `https://www.fabublox.com/process-editor/${lastPart}`;
    }

    return this.fieldValue; // Return the original value if it doesn't match patterns
  }
}