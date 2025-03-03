import Component from "@glimmer/component";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import i18n from "discourse-common/helpers/i18n";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import ProcessSelectorModal from "./process-selector-modal";

export default class TopicCustomFieldInput extends Component {
  @service siteSettings;
  @service modal;
  @readOnly("siteSettings.topic_custom_field_name") fieldName;
  @readOnly("siteSettings.topic_custom_field_type") fieldType;

  @action
  openProcessSelector() {
    this.modal.show(ProcessSelectorModal, {
      model: {
        onSelect: this.handleProcessSelected
      }
    });
  }

  @action
  handleProcessSelected(processData) {
    if (processData && processData.processUrl) {
      this.args.onChangeField(processData.processUrl);
      // If we have a store for the SVG data, we could save it here as well
      if (this.args.onSaveSvg && processData.svgContent) {
        this.args.onSaveSvg(processData.svgContent);
      }
    }
  }

  <template>
    {{#if (eq this.fieldType "boolean")}}
      <Input
        @type="checkbox"
        @checked={{@fieldValue}}
        {{on "change" (action @onChangeField value="target.checked")}}
      />
      <span>{{this.fieldName}}</span>
    {{/if}}

    {{#if (eq this.fieldType "integer")}}
      <Input
        @type="number"
        @value={{@fieldValue}}
        placeholder={{i18n
          "topic_custom_field.placeholder"
          field=this.fieldName
        }}
        class="topic-custom-field-input small"
        {{on "change" (action @onChangeField value="target.value")}}
      />
    {{/if}}

    {{#if (eq this.fieldType "string")}}
      <div class="process-selector-container">
        <Input
          @type="text"
          @value={{@fieldValue}}
          placeholder={{i18n
            "topic_custom_field.placeholder"
            field=this.fieldName
          }}
          class="topic-custom-field-input large"
          {{on "change" (action @onChangeField value="target.value")}}
        />
        <DButton
          @action={{this.openProcessSelector}}
          @icon="search"
          @label="Browse Processes"
          class="process-selector-button"
        />
      </div>
    {{/if}}

    {{#if (eq this.fieldType "json")}}
      <Textarea
        @value={{@fieldValue}}
        {{on "change" (action @onChangeField value="target.value")}}
        placeholder={{i18n
          "topic_custom_field.placeholder"
          field=this.fieldName
        }}
        class="topic-custom-field-textarea"
      />
    {{/if}}
  </template>
}
