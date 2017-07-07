LiveRecord.models.Category = LiveRecord.models.create(
  {
    modelName: 'Category',
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