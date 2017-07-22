module LiveRecord
  class InstallGenerator < Rails::Generators::Base
    desc 'Copy LiveRecord Javascript template'
    source_root File.expand_path('../templates', __FILE__)

    class_option :javascript_engine, desc: 'JS engine to be used: [js, coffee]'#, default: Rails.application.config.generators.options[:rails][:javascript_engine].to_s
    class_option :template_engine, desc: 'Template engine to be used (if LiveDom plugin enabled): [erb, slim, haml]'

    def copy_assets_javascript_template
      copy_file "javascript.#{javascript_engine}.rb", "lib/templates/#{javascript_engine}/assets/javascript.#{javascript_engine}"
    end

    def copy_model_model_template
      copy_file "model.rb.rb", "lib/templates/active_record/model/model.rb"
    end

    def copy_scaffold_index_template
      copy_file "index.html.#{template_engine}", "lib/templates/#{template_engine}/scaffold/index.html.#{template_engine}"
    end

    def copy_scaffold_show_template
      copy_file "show.html.#{template_engine}", "lib/templates/#{template_engine}/scaffold/show.html.#{template_engine}"
    end

    def copy_live_record_update_model
      class_collisions 'LiveRecordUpdate'
      template 'live_record_update.rb', File.join('app/models', 'live_record_update.rb')
      migration_template 'create_live_record_updates_migration.rb', 'db/migrate/create_live_record_updates.rb')
    end

    private

    def javascript_engine
      options[:javascript_engine]
    end

    def template_engine
      options[:template_engine]
    end
  end
end