<% module_namespacing do -%>
LiveRecord.Model.create(
  {
    modelName: '<%= singular_table_name.camelcase %>',
    plugins: {
      # remove this line if you're not using LiveDOM
      LiveDOM: true
    },

    ## More configurations below. See https://github.com/jrpolidario/live_record#example-1---model
    # belongsTo: {
    #  user: { foreignKey: 'user_id', modelName: 'User' }
    # },
    # hasMany: {
    #   books: { foreignKey: '<%= singular_table_name %>_id', modelName: 'Book' }
    # },
    # callbacks: {
    #   'on:disconnect': [],
    #   'after:update': [],
    # }
  }
)
<% end -%>
