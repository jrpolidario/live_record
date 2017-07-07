LiveRecord.Model.create(
  {
    modelName: 'Post',
    plugins: {
      LiveDom: true
    },
    callbacks: {
      'after:connect': [ 
        ( ->
          console.log('connected!!!')
        )
      ],
      'after:disconnect': [ 
        ( ->
          console.log('disconnected!!!')
        )
      ],
      'after:reconnect': [ 
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