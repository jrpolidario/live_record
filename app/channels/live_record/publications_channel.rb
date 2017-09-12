# This channel streams new records to connected clients whenever the "where" condition supplied by the client matches
# This implementation can be quite inefficient because there's only one pub-sub queue used for each model, but because of
# constraints ( see https://github.com/jrpolidario/live_record/issues/2 ) and because Users are authorised-validated anyway
# in each stream, then there's already an overhead delay. I am prioritising development convenience (as Rails does), in order
# to achieve a simpler API; in this example, it would be something like in JS:
# `LiveRecord.Model.all.Book.subscribe({where: is_enabled: true})`
class LiveRecord::PublicationsChannel < LiveRecord::BaseChannel

  def subscribed
    model_class = params[:model_name].safe_constantize

    if !(model_class && model_class < ApplicationRecord)
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end

    stream_from "live_record:publications:#{params[:model_name].underscore}", coder: ActiveSupport::JSON do |message|
      newly_created_record = model_class.find(message['attributes']['id'])

      @authorised_attributes ||= authorised_attributes(newly_created_record, current_user)
      
      active_record_relation = SearchAdapters.mapped_active_record_relation(
        model_class: model_class,
        conditions_hash: params[:where].to_h,
        current_user: current_user,
        authorised_attributes: @authorised_attributes
      )

      if active_record_relation.exists?(id: newly_created_record.id)
        # if not just :id
        if @authorised_attributes.size > 1
          message = { 'action' => 'create', 'attributes' => message['attributes'] }
          response = filtered_message(message, @authorised_attributes)
          transmit response if response.present?
        end
      end
    end
  end

  def sync_records(data)
    params = data.symbolize_keys
    model_class = params[:model_name].safe_constantize

    if model_class && model_class < ApplicationRecord

      records = model_class.where(
        'created_at >= ?', DateTime.parse(params[:stale_since]) - LiveRecord.configuration.sync_record_buffer_time
      )

      # we `transmmit` a message back to client for each matching record
      records.find_each do |record|
        # now we check each record if it is part of the "where" condition
        current_authorised_attributes = authorised_attributes(record, current_user)

        active_record_relation = SearchAdapters.mapped_active_record_relation(
          model_class: model_class,
          conditions_hash: params[:where].to_h,
          current_user: current_user,
          authorised_attributes: current_authorised_attributes
        )

        if active_record_relation.exists?(id: record)
          message = { 'action' => 'create', 'attributes' => record.attributes }
          response = filtered_message(message, current_authorised_attributes)
          transmit response if response.present?
        end
      end
    else
      respond_with_error(:bad_request, 'Not a correct model name')
      reject_subscription
    end
  end

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
        authorised_attributes = args.fetch(:authorised_attributes)

        current_active_record_relation = model_class.all

        conditions_hash.each do |key, value|
          operator = key.split('_').last
          # to get attribute_name, we subtract the end part of the string with size of operator substring; i.e.: created_at_lteq -> created_at
          attribute_name = key[0..(-1 - operator.size - 1)]

          if authorised_attributes == :all || authorised_attributes.include?(attribute_name)
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
            end
          end
        end

        current_active_record_relation
      end
    end
  end
end