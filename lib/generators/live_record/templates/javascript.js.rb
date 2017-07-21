<% module_namespacing do -%>
LiveRecord.Model.create(
  {
    modelName: '<%= file_name.singularize.camelcase %>',
    plugins: {
      LiveDOM: true
    },
    # See TODO: URL_TO_DOCUMENTATION for supported callbacks
    # Add Callbacks (callback name => array of functions)
    # callbacks: {
    #  'on:disconnect': [],
    #  'after:update': [],
    # }
  },
)
<% end -%>