# WIP! (Work-In-Progress)

## About

* Auto-syncs records in client-side JS (through a Model DSL) from changes in the backend Rails server through ActionCable
* Auto-updates DOM elements mapped to a record attribute, from changes. **(Optional Plugin)**
* Automatically resyncs after client-side reconnection.

> `live_record` is intentionally designed for read-only one-way syncing from the backend server, and does not support pushing changes to the Rails server from the client-side JS. Updates from client-side then is intended to use the normal HTTP REST requests.

## Requirements

* **>= Rails 5.0**

## Demo

## Usage Example

* on the client-side:

  ```js
  // instantiate a Book object
  var book = new LiveRecord.Model.all.Book({
    id: 1,
    title: 'Harry Potter',
    author: 'J. K. Rowling',
    created_at: '2017-08-02T12:39:49.238Z',
    updated_at: '2017-08-02T12:39:49.238Z'
  });
  // store this Book object into the JS store
  book.create();

  // the store is accessible through
  LiveRecord.Model.all.Book.all;

  // all records in the JS store are automatically subscribed to the backend LiveRecordChannel, which meant syncing (update / destroy) changes from the backend

  // you can add a callback that will be invoked whenever the Book object has been updated
  book.addCallback('after:update', function() {
    // let's say you update the DOM elements here when the attributes have changed
  });
  ```

* on the backend-side, you can handle attributes authorisation:

  ```ruby
  # app/models/book.rb
  class Book < ApplicationRecord
    def self.live_record_whitelisted_attributes(book, current_user)
      # Add attributes to this array that you would like `current_user` to have access to when syncing this particular `book`
      # empty array means not-authorised
      if book.user == current_user
        [:title, :author, :created_at, :updated_at, :reference_id, :origin_address]
      elsif current_user.present?
        [:title, :author, :created_at, :updated_at]
      else
        []
      end
    end
  end
  ```

* whenever a Book (or any other Model record that you specified) has been updated / destroyed, there exists an `after_update_commit` and an `after_destroy_commit` ActiveRecord callback that will broadcast changes to all subscribed JS clients

## Setup
* Add the following to your `Gemfile`:

  ```ruby
  gem 'live_record', '~> 0.0.1'
  ```

* Run:

  ```bash
  bundle install
  ```

* Install by running:

  ```bash
  rails generate live_record:install
  ```

  > `rails generate live_record:install --live_dom=false` if you do not need the `LiveDom` plugin; `--live_dom=true` by default

* Run migration to create the `live_record_updates` table, which is going to be used for client reconnection resyncing:

  ```bash
  rake db:migrate
  ```

* Update your **app/channels/application_cable/connection.rb**, and add `current_user` method, unless you already have it:

  ```ruby
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      identified_by :current_user

      def current_user
        # write something here if you have a current_user, or you may just leave this blank. Example below when using `devise` gem:
        # User.find_by(id: cookies.signed[:user_id])
      end
    end
  end
  ```

* Update your **model** files (only those you would want to be synced), and insert the following public method:

  > automatically updated if you use Rails scaffold or model generator

  ### Example 1 - Simple Usage

  ```ruby
  # app/models/book.rb (example 1)
  class Book < ApplicationRecord
    def self.live_record_whitelisted_attributes(book, current_user)
      # Add attributes to this array that you would like current_user to have access to when syncing.
      # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
      [:title, :author, :created_at, :updated_at]
    end
  end
  ```

  ### Example 2 - Advanced Usage

  ```ruby
  # app/models/book.rb (example 1)
  class Book < ApplicationRecord
    def self.live_record_whitelisted_attributes(book, current_user)
      # Notice that from above, you also have access to `book` (the record currently requested by the client to be synced),
      # and the `current_user`, the current user who is trying to sync the `book` record.
      if book.user == current_user
        [:title, :author, :created_at, :updated_at, :reference_id, :origin_address]
      elsif current_user.present?
        [:title, :author, :created_at, :updated_at]
      else
        []
      end
    end
  end
  ```

* For each Model you want to sync, insert the following in your Javascript files.

  > automatically updated if you use Rails scaffold or controller generator

  ### Example 1 - Model

  ```js
  // app/assets/javascripts/books.js
  LiveRecord.Model.create(
    {
      modelName: 'Book' // should match the Rails model name
      plugins: {
        LiveDOM: true // remove this if you do not need `LiveDom`
      }
    }
  )
  ```

  ### Example 2 - Model + Callbacks

  ```js
  // app/assets/javascripts/books.js
  LiveRecord.Model.create(
    {
      modelName: 'Book',
      callbacks: {
        'on:connect': [
          function() {
            console.log(this); // `this` refers to the current `Book` record that has just connected for syncing
          }
        ],
        'after:update': [
          function() {
            console.log(this); // `this` refers to the current `Book` record that has just been updated with changes synced from the backend
          }
        ]
      }
    }
  )
  ```

    #### Model Callbacks supported:
    * `on:connect`
    * `on:disconnect`
    * `on:connect`
    * `on:disconnect`
    * `on:response_error`
    * `before:create`
    * `after:create`
    * `before:update`
    * `after:update`
    * `before:destroy`
    * `after:destroy`

    > Each callback should map to an array of functions

    * `on:response_error` supports a function argument: The "Error Code". i.e.

      ### Example 3 - Handling Response Error

      ```js
      LiveRecord.Model.create(
        {
          modelName: 'Book',
          callbacks: {
            'on:response_error': [
              function(errorCode) {
                console.log(errorCode); // errorCode is a string, representing the type of error. See Response Error Codes below:
              }
            ]
          }
        }
      )
      ```

      #### Response Error Codes:
      * `"forbidden"` - Current User is not authorized to sync record changes. Happens when Model's `live_record_whitelisted_attributes` method returns empty array.
      * `"bad_request"` - Happens when `LiveRecord.Model.create({modelName: 'INCORRECTMODELNAME'})`

* Load the records into the JS Model-store through JSON REST (i.e.):

  ### Example 1 - Using Default Loader (Requires JQuery)

  > Your controller must also support responding with JSON in addition to HTML. If you used scaffold or controller generator, this should already work immediately.

  ```html
  <!-- app/views/books/index.html.erb -->
  <script>
    // `loadRecords` asynchronously loads all records (using the current URL) to the store, through a JSON AJAX request.
    // in this example, `loadRecords` will load JSON from the current URL which is /books
    LiveRecord.helpers.loadRecords({modelName: 'Book'})
  </script>
  ```

  ```html
  <!-- app/views/posts/index.html.erb -->
  <script>
    // You may also pass in a callback for synchronous logic
    LiveRecord.helpers.loadRecords({
      modelName: 'Book',
      onLoad: function(records) {
        // ...
      },
      onError: function(jqxhr, textStatus, error) {
        // ...
      }
    })
  </script>
  ```

  ### Example 2 - Using Custom Loader

  ```js
  // do something here that will fetch Book record attributes...
  // as an example, say you already have the following attributes:
  var book1Attributes = { id: 1, title: 'Noli Me Tangere', author: 'José Rizal' }
  var book2Attributes = { id: 2, title: 'ABNKKBSNPLAko?!', author: 'Bob Ong' }

  // then we instantiate a Book object
  var book1 = new LiveRecord.Model.all.Book(book1Attributes);
  // then we push this Book object to the Book store
  book1.create();

  var book2 = new LiveRecord.Model.all.Book(book2Attributes);
  book2.create();

  // you can also add Instance callbacks specific only to this Object (supported callbacks are the same as the Model callbacks)
  book2.addCallback('after:update', function() {
    // do something when book2 has been updated after syncing
  })
  ```


## Plugins

### LiveDom (Requires JQuery)

* enabled by default, unless explicitly removed.
* `LiveDom` allows DOM elements' text content to be automatically updated, whenever the mapped record-attribute has been updated.

> text content is safely escaped using JQuery's `.text()` function

#### Example 1 (Mapping to a Record-Attribute: `after:update`)
```html
<span data-live-record-update-from='Book-24-title'>Harry Potter</span>
```

* `data-live-record-update-from` format should be `MODELNAME-RECORDID-RECORDATTRIBUTE`
* whenever `LiveRecord.all.Book.all[24]` has been updated/synced from backend, "Harry Potter" text above changes accordingly.
* this does not apply to only `<span>` elements. You can use whatever elements you like.

#### Example 2 (Mapping to a Record: `after:destroy`)

```html
<section data-live-record-destroy-from='Book-31'>This example element is a container for the Book-31 record which can also contain children elements</section>
```

* `data-live-record-destroy-from` format should be `MODELNAME-RECORDID`
* whenever `LiveRecord.all.Book.all[31]` has been destroyed/synced from backend, the `<section>` element above is removed, and thus all of its children elements.
* this does not apply to only `<section>` elements. You can use whatever elements you like.

* You may combine `data-live-record-destroy-from` and `data-live-record-update-from` within the same element.