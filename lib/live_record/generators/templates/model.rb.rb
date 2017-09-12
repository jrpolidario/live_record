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
    # Add attributes to this array that you would like current_user to have access to.
    # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
    []
  end
end
<% end -%>