LiveRecord.Model.create(
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