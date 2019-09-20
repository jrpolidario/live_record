class LiveRecord::BaseChannel

  module Helpers
    def self.createable?
      record.class.live_record_createable?(current_user)
    end

    def self.readable?
      whitelisted_attributes = readable_attributes(record, current_user)
      !whitelisted_attributes.empty?
    end

    def self.updateable?(record, current_user)
      whitelisted_attributes = updateable_attributes(record, current_user)
      !whitelisted_attributes.empty?
    end

    def self.destroyable?
      record.class.live_record_destroyable?(record, current_user)
    end

    def self.readable_attributes(record, current_user)
      whitelisted_attributes = record.class.live_record_readable_attributes(record, current_user)

      unless whitelisted_attributes.is_a? Array
        raise "#{record.class}.live_record_readable_attributes should return an array"
      end

      whitelisted_attributes = whitelisted_attributes.map(&:to_s)

      if !whitelisted_attributes.empty? && !whitelisted_attributes.include?('id')
        raise "#{record.class}.live_record_readable_attributes should return an array that also includes the :id attribute, as you are authorizing at least one other attribute along with it."
      end

      whitelisted_attributes.to_set
    end

    def self.updateable_attributes(record, current_user)
      whitelisted_attributes = record.class.live_record_updateable_attributes(record, current_user)

      unless whitelisted_attributes.is_a? Array
        raise "#{record.class}.live_record_updateable_attributes should return an array"
      end

      whitelisted_attributes = whitelisted_attributes.map(&:to_s)
      whitelisted_attributes.to_set
    end

    def self.queryable_attributes(model_class, current_user)
      queryable_attributes = model_class.live_record_queryable_attributes(current_user)
      raise "#{model_class}.live_record_queryable_attributes should return an array" unless queryable_attributes.is_a? Array
      queryable_attributes = queryable_attributes.map(&:to_s)
      queryable_attributes.to_set
    end
  end
end
