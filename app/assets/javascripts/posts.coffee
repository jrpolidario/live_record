LiveRecord.store.post = LiveRecord.store.create(
  {
    model: 'post',
    enableDOMCallbacks: true,
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