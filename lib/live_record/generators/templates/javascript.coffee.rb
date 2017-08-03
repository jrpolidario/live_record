<% module_namespacing do -%>
LiveRecord.Model.create(
  {
    modelName: '<%= singular_table_name.camelcase %>',
    plugins: {
      LiveDOM: true
    },
    # See TODO: URL_TO_DOCUMENTATION for supported callbacks
    # Add Callbacks (callback name => array of functions)
    # callbacks: {
    #   'on:disconnect': [],
    #   'after:update': [],
    # }
  }
)
<% end -%>