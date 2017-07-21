LiveRecord.Model.create(
  {
    modelName: 'Post',
    plugins: {
      LiveDOM: true
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