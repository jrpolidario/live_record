<% module_namespacing do -%>
class <%= class_name %> < <%= parent_class_name.classify %>
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %><%= ', required: true' if attribute.required? %>
<% end -%>
<% attributes.select(&:token?).each do |attribute| -%>
  has_secure_token<% if attribute.name != "token" %> :<%= attribute.name %><% end %>
<% end -%>
<% if attributes.any?(&:password_digest?) -%>
  has_secure_password
<% end -%>

  include LiveRecord::Model::Callbacks
  has_many :live_record_updates, as: :recordable, dependent: :destroy

  def self.live_record_whitelisted_attributes(<%= class_name.underscore %>, current_user)
    # Add attributes to this array that you would like current_user client to be able to receive
    # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
    # i.e. if this file is a User model, and that a User has been created/updated in the backend,
    # then only these whitelisted attributes will be sent to this current_user client
    # Empty array means unauthorized
    # Example:
    # [:id, :email, :name, :is_admin, :group_id, :created_at, :updated_at]
    []
  end

  def self.live_record_queryable_attributes(current_user)
    # This method only applies when not using `ransack` gem!
    # If you're using ransack gem, instead of this method, use one or more of the ransack methods:
    # see https://github.com/activerecord-hackery/ransack#authorization-whitelistingblacklisting
    #
    # Add attributes to this array that you would like current_user client to be able to query upon when "subscribing"
    # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
    # i.e. if a current_user client subscribes to "new records creation" using `.subscribe({where: {...}})`,
    # then only these attributes will be considered in the "{where: ...}" argument
    # if you're using `ransack` gem, use `ransackable_attributes`
    # Empty array means unauthorized
    # Example:
    # [:id, :email, :name, :is_admin, :group_id, :created_at, :updated_at]
    []
  end
end
<% end -%>
