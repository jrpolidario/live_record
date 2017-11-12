class LiveRecord::BaseChannel

  module SearchAdapters
    def self.mapped_active_record_relation(**args)
      # if ransack is loaded, use ransack
      if Gem.loaded_specs.has_key? 'ransack'
        active_record_relation = RansackAdapter.mapped_active_record_relation(args)
      else
        active_record_relation = ActiveRecordDefaultAdapter.mapped_active_record_relation(args)
      end
      active_record_relation
    end

    module RansackAdapter
      def self.mapped_active_record_relation(**args)
        model_class = args.fetch(:model_class)
        conditions_hash = args.fetch(:conditions_hash)
        current_user = args.fetch(:current_user)

        model_class.ransack(conditions_hash, auth_object: current_user).result
      end
    end

    module ActiveRecordDefaultAdapter
      def self.mapped_active_record_relation(**args)
        model_class = args.fetch(:model_class)
        conditions_hash = args.fetch(:conditions_hash)
        current_user = args.fetch(:current_user)

        current_active_record_relation = model_class.all
        queryable_attributes = LiveRecord::BaseChannel::Helpers.queryable_attributes(model_class, current_user)

        conditions_hash.each do |key, value|
          operator = key.split('_').last
          # to get attribute_name, we subtract the end part of the string with size of operator substring; i.e.: created_at_lteq -> created_at
          attribute_name = key[0..(-1 - operator.size - 1)]

          if queryable_attributes.include?(attribute_name)
            case operator
            when 'eq'
              current_active_record_relation = current_active_record_relation.where(attribute_name => value)
            when 'not_eq'
              current_active_record_relation = current_active_record_relation.where.not(attribute_name => value)
            when 'gt'
              current_active_record_relation = current_active_record_relation.where(model_class.arel_table[attribute_name].gt(value))
            when 'gteq'
              current_active_record_relation = current_active_record_relation.where(model_class.arel_table[attribute_name].gteq(value))
            when 'lt'
              current_active_record_relation = current_active_record_relation.where(model_class.arel_table[attribute_name].lt(value))
            when 'lteq'
              current_active_record_relation = current_active_record_relation.where(model_class.arel_table[attribute_name].lteq(value))
            when 'in'
              current_active_record_relation = current_active_record_relation.where(attribute_name => Array.wrap(value))
            when 'not_in'
              current_active_record_relation = current_active_record_relation.where.not(attribute_name => Array.wrap(value))
            when 'matches'
              current_active_record_relation = current_active_record_relation.where("#{attribute_name} LIKE ?", value)
            when 'does_not_match'
              current_active_record_relation = current_active_record_relation.where("#{attribute_name} NOT LIKE ?", value)
            end
          end
        end

        current_active_record_relation
      end
    end
  end
end
