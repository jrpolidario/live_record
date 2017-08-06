LiveRecord.Model.create(
  {
    modelName: 'Post',
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
