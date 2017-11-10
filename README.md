[![Build Status](https://travis-ci.org/jrpolidario/live_record.svg?branch=master)](https://travis-ci.org/jrpolidario/live_record)
[![Gem Version](https://badge.fury.io/rb/live_record.svg)](https://badge.fury.io/rb/live_record)

## About

* Auto-syncs records in client-side JS (through a Model DSL) from changes (updates/destroy) in the backend Rails server through ActionCable.
* Also supports streaming newly created records to client-side JS
* Supports lost connection restreaming for both new records (create), and record-changes (updates/destroy).
* Auto-updates DOM elements mapped to a record attribute, from changes (updates/destroy). **(Optional LiveDOM Plugin)**

> `live_record` is intentionally designed for read-only one-way syncing from the backend server, and does not support pushing changes to the Rails server from the client-side JS. Updates from client-side then is intended to use the normal HTTP REST requests.

*New Version 0.2!*
*See [Changelog below](#changelog)*

## Requirements

* **Ruby >= 2.2.2**
* **Rails >= 5.0, < 5.2**

## Demo

* https://live-record-example.herokuapp.com/

## Usage Example

* say we have a `Book` model which has the following attributes:
  * `title:string`
  * `author:string`
  * `is_enabled:boolean`
* on the JS client-side:

### Subscribing to Record Creation
  ```js
  // subscribe and auto-receive newly created Book records from the Rails server
  LiveRecord.Model.all.Book.subscribe()

  // ... or also load all Book records as well (not just the new ones)
  // LiveRecord.Model.all.Book.subscribe({reload: true})

  // ...or only those which are enabled (you can also combine this with `reload: true`)
  // LiveRecord.Model.all.Book.subscribe({where: {is_enabled_eq: true}})

  // now, we can just simply add a "create" callback, to apply our own logic whenever a new Book record is streamed from the backend
  LiveRecord.Model.all.Book.addCallback('after:create', function() {
    // let's say you have a code here that adds this new Book on the page
    // `this` refers to the Book record that has been created
    console.log(this);
  })
  ```

### Subscribing to Record Updates/Destroy

  ```js
  // instantiate a Book object (only requirement is you pass the ID so it can be referenced when updates/destroy happen)
  var book = new LiveRecord.Model.all.Book({id: 1})

  // ...or you can also initialise with other attributes
  // var book = new LiveRecord.Model.all.Book({id: 1, title: 'Harry Potter', created_at: '2017-08-02T12:39:49.238Z'})

  // then store this Book object into the JS store
  book.create();

  // the store is accessible through
  LiveRecord.Model.all.Book.all;

  // all records in the JS store are automatically subscribed to the backend LiveRecord::ChangesChannel, which meant syncing (update / destroy) changes from the backend

  // All attributes automatically updates itself so you'll be sure that the following line (for example) is always up-to-date
  console.log(book.updated_at())

  // you can also add a callback that will be invoked whenever the Book object has been updated (see all supported callbacks further below)
  // i.e. you might want to update DOM elements when the attributes have changed
  book.addCallback('after:update', function() {
    // `this` refers to the Book record that has been updated

    console.log(this.attributes);
    // this book record should have been updated with all other possible whitelisted attributes even if you just initally passed in only the ID; thus console.log above would output below
    // {id: 1, title: 'Harry Potter', author: 'J.K. Rowling', is_enabled: true, created_at: '2017-08-02T12:39:49.238Z', updated_at: '2017-08-02T12:39:49.238Z'}

    console.log(this.changes)
    // from above, you can also access what has changed, and would have an example output below
    // {title: ['Harry Potter', 'New Title'], updated_at: ['2017-08-02T12:39:49.238Z', 2017-08-02T13:00:00.047Z]}
  });

  // or you can add a Model-wide callback that will be invoked whenever ANY Book object has been updated
  LiveRecord.Model.all.Book.addCallback('after:update', function() {
    console.log(this);
  })
  ```

* on the backend-side, you can handle attributes authorisation:

  ```ruby
  # app/models/book.rb
  class Book < ApplicationRecord
    include LiveRecord::Model::Callbacks
    has_many :live_record_updates, as: :recordable, dependent: :destroy

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

* whenever a Book (or any other Model record that you specified) has been created / updated / destroyed, there exists an `after_create_commit`, `after_update_commit` and an `after_destroy_commit` ActiveRecord callback that will broadcast changes to all subscribed JS clients

## Setup
1. Add the following to your `Gemfile`:

    ```ruby
    gem 'live_record', '~> 0.2.6'
    ```

2. Run:

    ```bash
    bundle install
    ```

3. Install by running:

    ```bash
    rails generate live_record:install
    ```

    > `rails generate live_record:install --live_dom=false` if you do not need the `LiveDOM` plugin; `--live_dom=true` by default

4. Run migration to create the `live_record_updates` table, which is going to be used for client reconnection resyncing:

  ```bash
  rake db:migrate
  ```

5. Update your **app/channels/application_cable/connection.rb**, and add `current_user` method, unless you already have it:

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

6. Update your **model** files (only those you would want to be synced), and insert the following public method:

    > automatically updated if you use Rails scaffold or model generator

    ### Example 1 - Simple Usage

    ```ruby
    # app/models/book.rb
    class Book < ApplicationRecord
      include LiveRecord::Model::Callbacks
      has_many :live_record_updates, as: :recordable, dependent: :destroy

      def self.live_record_whitelisted_attributes(book, current_user)
        # Add attributes to this array that you would like current_user to have access to when syncing.
        # Defaults to empty array, thereby blocking everything by default, only unless explicitly stated here so.
        [:title, :author, :created_at, :updated_at]
      end
    end
    ```

    ### Example 2 - Advanced Usage

    ```ruby
    # app/models/book.rb
    class Book < ApplicationRecord
      include LiveRecord::Model::Callbacks
      has_many :live_record_updates, as: :recordable, dependent: :destroy

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

7. For each Model you want to sync, insert the following in your Javascript files.

    > automatically updated if you use Rails scaffold or controller generator

    ### Example 1 - Model

    ```js
    // app/assets/javascripts/books.js
    LiveRecord.Model.create(
      {
        modelName: 'Book' // should match the Rails model name
        plugins: {
          LiveDOM: true // remove this if you do not need `LiveDOM`
        }
      }
    )
    ```

    ### Example 2 - Model + Callbacks + Associations

    ```js
    // app/assets/javascripts/books.js
    LiveRecord.Model.create(
      {
        modelName: 'Book',
        belongsTo: {
          // allows you to do `bookInstance.user()` and `bookInstance.library()`
          user: { foreignKey: 'user_id', modelName: 'User' },
          library: { foreignKey: 'library_id', modelName: 'Library' }
        },
        hasMany: {
          // allows you to do `bookInstance.pages()` and `bookInstance.bookReviews()`
          pages: { foreignKey: 'book_id', modelName: 'Page' },
          bookReviews: { foreignKey: 'book_id', modelName: 'Review' }
        },
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
      * `on:responseError`
      * `before:create`
      * `after:create`
      * `before:update`
      * `after:update`
      * `before:destroy`
      * `after:destroy`

      > Each callback should map to an array of functions

      * `on:responseError` supports a function argument: The "Error Code". i.e.

        ### Example 3 - Handling Response Error

        ```js
        LiveRecord.Model.create(
          {
            modelName: 'Book',
            callbacks: {
              'on:responseError': [
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

8. Load the records into the JS Model-store:

    * Any record created/loaded in the JS-store is automatically synced whenever it is updated from the backend
    * When reconnected after losing connection, the records in the store are synced automatically.

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
    <!-- app/views/books/index.html.erb -->
    <script>
      // `loadRecords` you may also specify a URL to loadRecords (`url` defaults to `window.location.href` which is the current page)
      LiveRecord.helpers.loadRecords({modelName: 'Book', url: '/some/url/that/returns_books_as_a_json'})
    </script>
    ```

    ```html
    <!-- app/views/books/index.html.erb -->
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
    // then we push this Book object to the Book store, which then automatically subscribes them to changes in the backend
    book1.create();

    var book2 = new LiveRecord.Model.all.Book(book2Attributes);
    book2.create();

    // you can also add Instance callbacks specific only to this Object (supported callbacks are the same as the Model callbacks)
    book2.addCallback('after:update', function() {
      // do something when book2 has been updated after syncing
    })
    ```

9. To automatically receive new Book records, and/or also load the old ones, you may subscribe:

    ```js
    // subscribe and auto-fetches newly created Book records from the backend
    var subscription = LiveRecord.Model.all.Book.subscribe();

    // ...or also load all Book records (not just the new ones).
    // useful for populating records at the start, and therefore you may skip using `LiveRecord.helpers.loadRecords()` already
    // subscription = LiveRecord.Model.all.Book.subscribe({reload: true});

    // ...or subscribe only to certain conditions (i.e. when `is_enabled` attribute value is `true`)
    // For the list of supported operators (like `..._eq`), see JS API `MODEL.subscribe(CONFIG)` below
    // subscription = LiveRecord.Model.all.Book.subscribe({where: {is_enabled_eq: true}});

    // you may choose to combine both `where` and `reload` arguments described above

    // now, we can just simply add a "create" callback, to apply our own logic whenever a new Book record is streamed from the backend
    LiveRecord.Model.all.Book.addCallback('after:create', function() {
      // let's say you have a code here that adds this new Book on the page
      // `this` refers to the Book record that has been created
      console.log(this);
    })

    // you may also add callbacks specific to this `subscription`, as you may want to have multiple subscriptions. Then, see JS API `MODEL.subscribe(CONFIG)` below for information

    // you may also want to unsubscribe as you wish
    LiveRecord.Model.all.Book.unsubscribe(subscription);
    ```

    ### Ransack Search Queries (Optional)

      * If you need more complex queries to pass into the `.subscribe(where: { ... })` above, [ransack](https://github.com/activerecord-hackery/ransack) gem is supported.
      * For example you can then do:
        ```js
        // querying upon the `belongs_to :user`
        subscription = LiveRecord.Model.all.Book.subscribe({where: {user_is_admin_eq: true, is_enabled_eq: true}});

        // or querying "OR" conditions
        subscription = LiveRecord.Model.all.Book.subscribe({where: {title_eq: 'I am Batman', content_eq: 'I am Batman', m: 'or'}});
        ```

      #### Model File (w/ Ransack) Example

      ```ruby
      # app/models/book.rb
      class Book < ApplicationRecord
        include LiveRecord::Model::Callbacks
        has_many :live_record_updates, as: :recordable, dependent: :destroy

        def self.live_record_whitelisted_attributes(book, current_user)
          [:title, :is_enabled]
        end

        private

        # see ransack gem for more details: https://github.com/activerecord-hackery/ransack#authorization-whitelistingblacklisting
        # you can write your own columns here, but you may just simply allow ALL COLUMNS to be searchable, because the `live_record_whitelisted_attributes` method above will be also called anyway, and therefore just simply handle whitelisting there.
        # therefore you can actually remove the whole `self.ransackable_attributes` method below

        ## LiveRecord passes the `current_user` into `auth_object`, so you can access `current_user` inside below
        # def self.ransackable_attributes(auth_object = nil)
        #   column_names + _ransackers.keys
        # end
      end
      ```

    ### Reconnection Streaming For New Records (when client got disconnected)

    * To be able to stream newly created records upon reconnection, the only requirement is that you should have a `created_at` attribute on your Models, which by default should already be there. However, to speed up queries, I highly suggest to add index on `created_at` with the following

    ```bash
    # this will create a file under db/migrate folder, then edit that file (see the ruby code below)
    rails generate migration add_created_at_index_to_MODELNAME
    ```

    ```ruby
    # db/migrate/2017**********_add_created_at_index_to_MODELNAME.rb
    class AddCreatedAtIndexToMODELNAME < ActiveRecord::Migration[5.0] # or 5.1, etc
      def change
        add_index :TABLENAME, :created_at
      end
    end
    ```

## Plugins

### LiveDOM (Requires JQuery)

* enabled by default, unless explicitly removed.
* `LiveDOM` allows DOM elements' text content to be automatically updated, whenever the mapped record-attribute has been updated.

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

## JS API

### `LiveRecord.Model.all`
  * Object of which properties are the models

### `LiveRecord.Model.create(CONFIG)`
  * `CONFIG` (Object)
    * `modelName`: (String, Required)
    * `belongsTo`: (Object)
      * `ASSOCIATIONNAME`: (Object)
        * `foreignKey`: (String)
        * `modelName`: (String)
    * `hasMany`: (Object)
      * `ASSOCIATIONNAME`: (Object)
        * `foreignKey`: (String)
        * `modelName`: (String)
    * `callbacks`: (Object)
      * `on:connect`: (Array of functions)
      * `on:disconnect`: (Array of functions)
      * `on:responseError`: (Array of functions; function argument = ERROR_CODE (String))
      * `before:create`: (Array of functions)
      * `after:create`: (Array of functions)
      * `before:update`: (Array of functions)
      * `after:update`: (Array of functions)
      * `before:destroy`: (Array of functions)
      * `after:destroy`: (Array of functions)
    * `plugins`: (Object)
      * `LiveDOM`: (Boolean)
  * creates a `MODEL` and stores it into `LiveRecord.Model.all` array
  * `hasMany` and `belongsTo` `modelName` above should be a valid defined `LiveRecord.Model`
  * returns the newly created `MODEL`

### `MODEL.all`
  * Object of which properties are IDs of the records

### `MODEL.subscribe(CONFIG)`
  * `CONFIG` (Object, Optional)
    * `reload`: (Boolean, Default: false)
    * `where`: (Object)
      * `ATTRIBUTENAME_OPERATOR`: (Any Type)
    * `callbacks`: (Object)
      * `on:connect`: (function Object)
      * `on:disconnect`: (function Object)
      * `before:create`: (function Object)
      * `after:create`: (function Object)
  * subscribes to the `LiveRecord::PublicationsChannel`, which then automatically receives new records from the backend.
  * when `reload: true`, all records (subject to `where` condition above) are immediately loaded, and not just the new ones.
  * you can also pass in `callbacks` (see above). These callbacks are only applicable to this subscription, and is independent of the Model and Instance callbacks.
  * `ATTRIBUTENAME_OPERATOR` means something like (for example): `is_enabled_eq`, where `is_enabled` is the `ATTRIBUTENAME` and `eq` is the `OPERATOR`.
    * you can have as many `ATTRIBUTENAME_OPERATOR` as you like, but keep in mind that the logic applied to them is "AND", and not "OR". For "OR" conditions, use `ransack`

    #### List of Default Supported Query Operators

    > the following list only applies if you are NOT using the `ransack` gem. If you need more complex queries, `ransack` is supported and so see Setup's step 9 above

    * `eq` equals; i.e. `is_enabled_eq: true`
    * `not_eq` not equals; i.e. `title_not_eq: 'Harry Potter'`
    * `lt` less than; i.e. `created_at_lt: '2017-12-291T13:47:59.238Z'`
    * `lteq` less than or equal to; i.e. `created_at_lteq: '2017-12-291T13:47:59.238Z'`
    * `gt` greater than; i.e. `created_at_gt: '2017-12-291T13:47:59.238Z'`
    * `gteq` greater than or equal to; i.e. `created_at_gteq: '2017-12-291T13:47:59.238Z'`
    * `in` in Array; i.e. `id_in: [2, 56, 19, 68]`
    * `not_in` in Array; i.e. `id_not_in: [2, 56, 19, 68]`

### `MODEL.unsubscribe(SUBSCRIPTION)`
  * unsubscribes to the `LiveRecord::PublicationsChannel`, thereby will not be receiving new records anymore.

### `new LiveRecord.Model.all.MODELNAME(ATTRIBUTES)`
  * `ATTRIBUTES` (Object)
  * returns a `MODELINSTANCE` of the the Model having `ATTRIBUTES` attributes

### `MODELINSTANCE.modelName()`
  * returns the model name (i.e. 'Book')

### `MODELINSTANCE.attributes`
  * the attributes object

### `MODELINSTANCE.ATTRIBUTENAME()`
  * returns the attribute value of corresponding to `ATTRIBUTENAME`. (i.e. `bookInstance.id()`, `bookInstance.created_at()`)

### `MODELINSTANCE.ASSOCIATIONAME()`
  * if association is "has many", then returns an array of associated records (if any exists in current store)
  * if association is "belongs to", then returns the record (if exists in current store)
  * (i.e. `bookInstance.user()`, `bookInstance.reviews()`)

### `MODELINSTANCE.subscribe(config)`
  * `CONFIG` (Object, Optional)
    * `reload`: (Boolean, Default: false)
  * subscribes to the `LiveRecord::ChangesChannel`. This instance should already be subscribed by default after being stored, unless there is a `on:response_error` or manually `unsubscribed()` which then you should manually call this `subscribe()` function after correctly handling the response error, or whenever desired.
  * when `reload: true`, the record is forced reloaded to make sure all attributes are in-sync
  * returns the `subscription` object (the ActionCable subscription object itself)

### `MODELINSTANCE.unsubscribe()`
  * unsubscribes to the `LiveRecord::ChangesChannel`, thereby will not be receiving changes (updates/destroy) anymore.

### `MODELINSTANCE.isSubscribed()`
  * returns `true` or `false` accordingly if the instance is subscribed

### `MODELINSTANCE.subscription`
  * the `subscription` object (the ActionCable subscription object itself)

### `MODELINSTANCE.create()`
  * stores the instance to the store, and then `subscribe({reload: true})` to the `LiveRecord::ChangesChannel` for syncing
  * returns the instance

### `MODELINSTANCE.update(ATTRIBUTES)`
  * `ATTRIBUTES` (Object)
  * updates the attributes of the instance
  * returns the instance

### `MODELINSTANCE.destroy()`
  * removes the instance from the store, and then `unsubscribe()`
  * returns the instance

### `MODELINSTANCE.changes`
  * you can **ONLY** access this inside the function callback for `before:update` and `after:update`, and is automatically cleared after
  * returns an object having the same format as [Rails's own `changes`](https://apidock.com/rails/ActiveModel/Dirty/changes)
  * i.e. `{title: ['Harry Potter', 'New Title'], updated_at: ['2017-08-02T12:39:49.238Z', 2017-08-02T13:00:00.047Z]}`

### `MODELINSTANCE.addCallback(CALLBACKKEY, CALLBACKFUNCTION)`
  * `CALLBACKKEY` (String) see supported callbacks above
  * `CALLBACKFUNCTION` (function Object)
  * returns the function Object if successfuly added, else returns `false` if callback already added

### `MODELINSTANCE.removeCallback(CALLBACKKEY, CALLBACKFUNCTION)`
  * `CALLBACKKEY` (String) see supported callbacks above
  * `CALLBACKFUNCTION` (function Object) the function callback that will be removed
  * returns the function Object if successfully removed, else returns `false` if callback is already removed

## FAQ
* How to remove the view templates being overriden by LiveRecord when generating a controller or scaffold?
  * amongst other things, `rails generate live_record:install` will override the default scaffold view templates: **show.html.erb** and **index.html.erb**; to revert back, just simply delete the following files (though you'll need to manually update or regenerate the view files that were already generated prior to deleting the following files):
    * **lib/templates/erb/scaffold/index.html.erb**
    * **lib/templates/erb/scaffold/show.html.erb**

* How to support more complex queries / "where" conditions when subscribing to new records creation?
  * Please refer to [JS API's MODEL.subscribe(CONFIG) above ](#modelsubscribeconfig)

## TODOs
* Change `feature` specs into `system` specs after [this rspec-rails pull request](https://github.com/rspec/rspec-rails/pull/1813) gets merged.

## Contributing
* pull requests and forks are very much welcomed! :) Let me know if you find any bug! Thanks

## License
* MIT

## Changelog
* 0.2.6
  * fixed minor bug where `MODELINSTANCE.changes` do not accurately work on NULL values.
* 0.2.5
  * fixed a major bug where same-model record instances were all sharing the same `@_callbacks` object, which then effectively calling also callbacks not specifically defined just for a specific record instance.
* 0.2.4
  * you can now pass in `{reload: true}` to `subscribe()` like the folowing:
    * `MODEL.subscribe({reload: true})` to immediately load all records from backend, and not just the new ones
    * `MODELINSTANCE.subscribe({reload: true})` to immediately reload the record and make sure it's in-sync
* 0.2.3
  * IMPORTANT! renamed callback from `on:response_error` to `on:responseError` for conformity. So please update your code accordingly.
  * added [associations](#example-2---model--callbacks--associations):
    * `hasMany` which allows you to do `bookInstance.reviews()`
    * `belongsTo` which allows you to do `bookInstance.user()`
  * fixed `loadRecords()` throwing an error when there is no response
* 0.2.2
  * minor fix: "new records" subscription: `.modelName` was not being referenced properly, but should have not affected any functionalities.
* 0.2.1
  * you can now access what attributes have changed; see [`MODELINSTANCE.changes`](#modelinstancechanges) above.
* 0.2.0
  * Ability to subscribe to new records (supports lost connection auto-restreaming)
    * See [9th step of Setup above](#setup)
