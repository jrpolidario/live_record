module LiveRecord
  module ActionViewExtensions
    module ViewHelper
      def live_record_element(record)
        raw " data-live-record-element='#{record.class.name}-#{record.id}' "
      end

      def live_record_updatable(record, attribute)
        raise ArgumentError, "[#{record.class}] does not have an attribute named [#{attribute}]" unless record.attribute_names.include? attribute.to_s
        raw " data-live-record-update-from='#{record.class.name}-#{record.id}-#{attribute}' "
      end

      def live_record_destroyable(record)
        raw " data-live-record-destroy-from='#{record.class.name}-#{record.id}' "
      end
    end
  end
end

ActiveSupport.on_load(:action_view) do
  include LiveRecord::ActionViewExtensions::ViewHelper
end
