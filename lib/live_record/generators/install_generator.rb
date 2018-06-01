module LiveRecord
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Copy LiveRecord Javascript template'
      source_root File.expand_path('../templates', __FILE__)

      class_option :live_dom, desc: 'Enables LiveDom plugin: [true, false]', default: 'true'
      class_option :javascript_engine, desc: 'JS engine to be used: [js, coffee]'
      class_option :template_engine, desc: 'Template engine to be used (if LiveDom plugin enabled): [erb, slim, haml]'

      def copy_assets_javascript_template
        copy_file "javascript.#{javascript_engine}.rb", "lib/templates/#{javascript_engine}/assets/javascript.#{javascript_engine}"
      end

      def copy_model_template
        copy_file "model.rb.rb", "lib/templates/active_record/model/model.rb"
      end

      def copy_scaffold_index_template
        copy_file "index.html.#{template_engine}", "lib/templates/#{template_engine}/scaffold/index.html.#{template_engine}" if live_dom
      end

      def copy_scaffold_show_template
        copy_file "show.html.#{template_engine}", "lib/templates/#{template_engine}/scaffold/show.html.#{template_engine}" if live_dom
      end

      def copy_live_record_update_model_template
        class_collisions 'LiveRecordUpdate'
        template 'live_record_update.rb', File.join('app/models', 'live_record_update.rb')
        migration_template 'create_live_record_updates.rb', 'db/migrate/create_live_record_updates.rb'
      end

      # def copy_live_record_changes_channel_template
      #   class_collisions 'LiveRecordChangesChannel'
      #   template 'live_record_changes_channel.rb', File.join('app/channels', 'live_record_changes_channel.rb')
      # end

      # def copy_live_record_publication_channel_template
      #   class_collisions 'LiveRecordPublicationChannel'
      #   template 'live_record_publication_channel.rb', File.join('app/channels', 'live_record_publication_channel.rb')
      # end

      def update_application_javascript
        in_root do
          insert_into_file 'app/assets/javascripts/application.js', "//= require live_record\n", before: "//= require_tree ."
          insert_into_file 'app/assets/javascripts/application.js', "//= require live_record/plugins/live_dom\n", before: "//= require_tree ." if live_dom
        end
      end

      def update_cable_javascript
        in_root do
          insert_into_file 'app/assets/javascripts/cable.js', "\n  LiveRecord.init(App.cable);", after: "App.cable = ActionCable.createConsumer();"
        end
      end

      private

      def self.next_migration_number(dir)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      def javascript_engine
        Rails.application.config.generators.options[:rails][:javascript_engine] || options[:javascript_engine]
      end

      def template_engine
        Rails.application.config.generators.options[:rails][:template_engine] || options[:template_engine]
      end

      def live_dom
        options[:live_dom] == 'true' ? true : options[:live_dom] == 'false' ? false : raise(ArgumentError, 'invalid value for --live_dom. Can only be `true` or `false`')
      end
    end
  end
end
