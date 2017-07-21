LiveRecord.Model.create(
  {
    modelName: 'Category',
    plugins: {
      LiveDOM: true
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