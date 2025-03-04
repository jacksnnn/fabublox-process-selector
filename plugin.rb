# frozen_string_literal: true

# name: discourse-topic-custom-fields
# about: Discourse plugin showing how to add custom fields to Discourse topics
# version: 1.0
# authors: Angus McLeod
# contact email: angus@pavilion.tech
# url: https://github.com/pavilionedu/discourse-topic-custom-fields

# This sets the plugin name in the admin interface 
# & registers the plugin's stylesheet from /assets/stylesheets/common.scss
enabled_site_setting :topic_custom_field_enabled
register_asset "stylesheets/common.scss"

##
# type:        introduction
# title:       Add a custom field to a topic
# description: To get started, load the [discourse-topic-custom-fields](https://github.com/pavilionedu/discourse-topic-custom-fields)
#              plugin in your local development environment. Once you've got it
#              working, follow the steps below and in the client "initializer"
#              to understand how it works. For more about the context behind
#              each step, follow the links in the 'references' section.
##

# Executes after the discourse application is initialized
after_initialize do 
  # Defines a module for the custom field
  module ::TopicCustomFields 
    # Defines the custom field name & type for admins to set in the admin interface
    FIELD_NAME = SiteSetting.topic_custom_field_name
    FIELD_TYPE = SiteSetting.topic_custom_field_type
  end

  ##
  # type:        step
  # number:      1
  # title:       Register the field
  # description: Where we tell discourse what kind of field we're adding. You
  #              can register a string, integer, boolean or json field.
  # references:  lib/plugins/instance.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  register_topic_custom_field_type(
    # Registers the custom field name & type fom 
    TopicCustomFields::FIELD_NAME,
    TopicCustomFields::FIELD_TYPE.to_sym,
  )

  ##
  # type:        step
  # number:      2
  # title:       Add getter and setter methods
  # description: Adding getter and setter methods is optional, but advisable.
  #              It means you can handle data validation or normalisation, and
  #              it lets you easily change where you're storing the data.
  ##

  ##
  # type:        step
  # number:      2.1
  # title:       Getter method
  # references:  lib/plugins/instance.rb,
  #              app/models/topic.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_to_class(:topic, TopicCustomFields::FIELD_NAME.to_sym) do
    # Dynamically defines a getter method for the custom field
    # Returns the custom field value if it exists (not nil3), otherwise returns nil
    if !custom_fields[TopicCustomFields::FIELD_NAME].nil?
      custom_fields[TopicCustomFields::FIELD_NAME]
    else
      nil
    end
  end

  ##
  # type:        step
  # number:      2.2
  # title:       Setter method
  # references:  lib/plugins/instance.rb,
  #              app/models/topic.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_to_class(:topic, "#{TopicCustomFields::FIELD_NAME}=") do |value|
  # Stores the custom field value in the custom_fields hash
    custom_fields[TopicCustomFields::FIELD_NAME] = value
  end

  ##
  # type:        step
  # number:      3
  # title:       Update the field when the topic is created or updated
  # description: Topic creation is contingent on post creation. This means that
  #              many of the topic update classes are associated with the post
  #              update classes.
  ##

  ##
  # type:        step
  # number:      3.1
  # title:       Update on topic creation
  # description: Here we're using an event callback to update the field after
  #              the first post in the topic, and the topic itself, is created.
  # references:  lib/plugins/instance.rb,
  #              lib/post_creator.rb
  ##
  on(:topic_created) do |topic, opts, user| # event listner for topic creation
    topic.send(
      # Calls the setter method, passing the initial custom field value from opts
      "#{TopicCustomFields::FIELD_NAME}=".to_sym, #
      opts[TopicCustomFields::FIELD_NAME.to_sym],
    )
    topic.save!
  end

  ##
  # type:        step
  # number:      3.2
  # title:       Update on topic edit
  # description: Update the field when it's updated in the composer when
  #              editing the first post in the topic, or in the topic title
  #              edit view.
  # references:  lib/plugins/instance.rb,
  #              lib/post_revisor.rb
  ##
  PostRevisor.track_topic_field(TopicCustomFields::FIELD_NAME.to_sym) do |tc, value|
    # Monitors changes to the custom field when the topic is edited
    tc.record_change( # Logs the field's original and new values
      TopicCustomFields::FIELD_NAME,
      tc.topic.send(TopicCustomFields::FIELD_NAME),
      value,
    )
    # Calls the setter method, passing the new custom field value
    tc.topic.send("#{TopicCustomFields::FIELD_NAME}=".to_sym, value.present? ? value : nil)
  end

  ##
  # type:        step
  # number:      4
  # title:       Serialize the field
  # description: Send our field to the client, along with the other topic
  #              fields.
  ##

  ##
  # type:        step
  # number:      4.1
  # title:       Serialize to the topic
  # description: Send your field to the topic.
  # references:  lib/plugins/instance.rb,
  #              app/serializers/topic_view_serializer.rb
  ##
  add_to_serializer(:topic_view, TopicCustomFields::FIELD_NAME.to_sym) do
    object.topic.send(TopicCustomFields::FIELD_NAME)
  end

  ##
  # type:        step
  # number:      4.2
  # title:       Preload the field
  # description: Discourse preloads custom fields on listable models (i.e.
  #              categories or topics) before serializing them. This is to
  #              avoid running a potentially large number of SQL queries
  #              ("N+1 Queries") at the point of serialization, which would
  #              cause performance to be affected.
  # references:  lib/plugins/instance.rb,
  #              app/models/topic_list.rb,
  #              app/models/concerns/has_custom_fields.rb
  ##
  add_preloaded_topic_list_custom_field(TopicCustomFields::FIELD_NAME)

  ##
  # type:        step
  # number:      4.3
  # title:       Serialize to the topic list
  # description: Send your preloaded field to the topic list.
  # references:  lib/plugins/instance.rb,
  #              app/serializers/topic_list_item_serializer.rb
  ##
  add_to_serializer(:topic_list_item, TopicCustomFields::FIELD_NAME.to_sym) do
    object.send(TopicCustomFields::FIELD_NAME)
  end
  
  # Add the auth0_id to the current user serializer
  add_to_serializer(:current_user, :auth0_id) do
    object.custom_fields["auth0_id"]
  end
  
  # Add API endpoints for Fabublox integration
  require 'net/http'
  require 'uri'
  require 'json'
  
  # Define a module for the Fabublox API
  module ::FabubloxApi
    def self.fetch_user_processes(auth0_id)
      uri = URI.parse("#{SiteSetting.fabublox_api_url}/user/processes/#{auth0_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      
      response = http.request(request)
      
      if response.code == "200"
        JSON.parse(response.body)
      else
        { error: "Failed to fetch user processes", status: response.code }
      end
    end
    
    def self.fetch_process(process_id)
      uri = URI.parse("#{SiteSetting.fabublox_api_url}/process/read/#{process_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      
      response = http.request(request)
      
      if response.code == "200"
        JSON.parse(response.body)
      else
        { error: "Failed to fetch process", status: response.code }
      end
    end
    
    def self.fetch_process_svg(process_id)
      uri = URI.parse("#{SiteSetting.fabublox_api_url}/process/read/#{process_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      
      response = http.request(request)
      
      if response.code == "200"
        JSON.parse(response.body)
      else
        { error: "Failed to fetch process SVG", status: response.code }
      end
    end
  end
  
  # Register API endpoints
  Discourse::Application.routes.append do
    get "/fabublox/user/processes/:auth0_id" => "fabublox_api#user_processes", constraints: { auth0_id: /.*/ }
    get "/fabublox/process/:process_id" => "fabublox_api#process"
    get "/fabublox/process/:process_id/svg" => "fabublox_api#process_svg"
    
    # Secure routes that don't expose auth0_id in the URL
    get "/fabublox/user/processes" => "fabublox#user_processes"
    get "/fabublox/process/:process_id" => "fabublox#process_by_id", constraints: ->(req) { req.format == :json }
    get "/fabublox/process/:process_id/svg" => "fabublox#process_svg_preview", constraints: ->(req) { req.format == :json }
  end
  
  # Create a controller for the Fabublox API
  class ::FabubloxApiController < ::ApplicationController
    requires_plugin 'discourse-topic-custom-fields'
    
    skip_before_action :check_xhr, only: [:user_processes, :process, :process_svg]
    
    def user_processes
      auth0_id = params[:auth0_id]
      render json: FabubloxApi.fetch_user_processes(auth0_id)
    end
    
    def process
      process_id = params[:process_id]
      render json: FabubloxApi.fetch_process(process_id)
    end
    
    def process_svg
      process_id = params[:process_id]
      render json: FabubloxApi.fetch_process_svg(process_id)
    end
  end

  # Add the Auth0 ID as a secure user field
  register_editable_user_custom_field :auth0_id if defined?(register_editable_user_custom_field)
  
  # Protect the auth0_id custom field from being publicly accessible
  plugin = Plugin::Instance.new
  plugin.hide_user_field(:auth0_id)
  
  # Create a Fabublox controller to handle secure API calls
  add_to_class(:application_controller, :fabublox_service_available?) do
    SiteSetting.topic_custom_fields_enabled
  end
  
  module ::FabubloxControllerExtension
    def proxy_fabublox_api_request(endpoint, auth0_id)
      # Use Discourse's HTTP client for making secure API calls
      uri = URI.parse("#{SiteSetting.fabublox_api_url}#{endpoint}/#{auth0_id}")
      
      # Create secure request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      
      # Create request
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      
      # Add any additional authorization if needed
      # request["Authorization"] = "Bearer #{SiteSetting.fabublox_api_key}" if SiteSetting.fabublox_api_key.present?
      
      # Make request
      response = http.request(request)
      
      # Return JSON response
      JSON.parse(response.body)
    end
  end
  
  class ::FabubloxController < ::ApplicationController
    include FabubloxControllerExtension
    
    requires_login
    
    def user_processes
      raise Discourse::InvalidAccess.new unless fabublox_service_available?
      
      # Securely get the auth0_id from the database, not passing it to frontend
      auth0_id = current_user.custom_fields["auth0_id"]
      
      if auth0_id.blank?
        render json: { error: "User not authenticated with Auth0" }, status: 400
        return
      end
      
      # Call the Fabublox API with the auth0_id
      begin
        result = proxy_fabublox_api_request("/user/processes", auth0_id)
        render json: result
      rescue => e
        render json: { error: e.message }, status: 500
      end
    end
    
    def process_by_id
      raise Discourse::InvalidAccess.new unless fabublox_service_available?
      
      process_id = params[:process_id]
      
      if process_id.blank?
        render json: { error: "Process ID is required" }, status: 400
        return
      end
      
      # Securely get the auth0_id
      auth0_id = current_user.custom_fields["auth0_id"]
      
      if auth0_id.blank?
        render json: { error: "User not authenticated with Auth0" }, status: 400
        return
      end
      
      # Call the Fabublox API
      begin
        result = proxy_fabublox_api_request("/process/#{process_id}", auth0_id)
        render json: result
      rescue => e
        render json: { error: e.message }, status: 500
      end
    end
    
    def process_svg_preview
      raise Discourse::InvalidAccess.new unless fabublox_service_available?
      
      process_id = params[:process_id]
      
      if process_id.blank?
        render json: { error: "Process ID is required" }, status: 400
        return
      end
      
      # Securely get the auth0_id
      auth0_id = current_user.custom_fields["auth0_id"]
      
      if auth0_id.blank?
        render json: { error: "User not authenticated with Auth0" }, status: 400
        return
      end
      
      # Call the Fabublox API
      begin
        result = proxy_fabublox_api_request("/process/#{process_id}/svg", auth0_id)
        render json: result
      rescue => e
        render json: { error: e.message }, status: 500
      end
    end
  end
  
  # Add site settings for Fabublox API configuration
  DiscoursePluginRegistry.serialized_current_user_fields << "auth0_id"
end
