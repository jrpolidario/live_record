class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_create :broadcast_record_create
  after_update :broadcast_record_update
  after_destroy :broadcast_record_destroy

  private

  def broadcast_record_create
  	model_name = self.class.to_s.underscore
  	ActionCable.server.broadcast("records_#{model_name}_create", model_name => self)
  end

  def broadcast_record_update
  	model_name = self.class.to_s.underscore
  	ActionCable.server.broadcast("records_#{model_name}_update_#{id}", model_name => self.attributes.slice(*self.changed))
  end

  def broadcast_record_destroy
  	model_name = self.class.to_s.underscore
  	ActionCable.server.broadcast("records_#{model_name}_destroy_#{id}", nil)
  end
end
