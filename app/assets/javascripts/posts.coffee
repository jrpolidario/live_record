LiveRecord.models.Post = LiveRecord.models.create(
  {
    modelName: 'Post',
    plugins: {
      LiveDom: true
    },
    callbacks: {
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