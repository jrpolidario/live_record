LiveRecord.store.category = LiveRecord.store.create(
  {
    model: 'category',
    plugins: {
      liveDom: true
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