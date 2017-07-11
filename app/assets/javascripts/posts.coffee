LiveRecord.Model.create(
  {
    modelName: 'Post',
    plugins: {
      LiveDom: true
    },
    callbacks: {
      'on:connect': [ 
        ( ->
          console.log('connected!!!')
        )
      ],
      'on:disconnect': [ 
        ( ->
          console.log('disconnected!!!')
        )
      ],
      'on:reconnect': [ 
        ( ->
          console.log('reconnected!!!')
        )
      ],
      'after:destroy': [
        ( ->
          console.log('AAA')
        ),
        ( ->
          console.log('BBB')
        )
      ]
    }
  },
)