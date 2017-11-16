require 'rails_helper'

RSpec.feature 'LiveRecord Syncing', type: :feature do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:post1) { create(:post, user: user1) }
  let(:post2) { create(:post, user: user1) }
  let(:post3) { create(:post, user: nil) }
  let!(:users) { [user1, user2] }
  let!(:posts) { [post1, post2, post3] }

  scenario 'User sees live changes (updates) of post records', js: true do
    visit '/posts'

    execute_script("LiveRecord.helpers.loadRecords({ modelName: 'Post' });")

    post1_title_td = find('td', text: post1.title, wait: 10)
    post2_title_td = find('td', text: post2.title, wait: 10)
    post3_title_td = find('td', text: post3.title, wait: 10)

    post1.update!(title: 'post1newtitle')
    post2.update!(title: 'post2newtitle')

    expect(post1_title_td).to have_content('post1newtitle', wait: 10)
    expect(post2_title_td).to have_content('post2newtitle', wait: 10)
    expect(post3_title_td).to have_content(post3.title, wait: 10)
  end

  scenario 'User sees live changes (destroy) of post records', js: true do
    visit '/posts'

    execute_script("LiveRecord.helpers.loadRecords({ modelName: 'Post' });")

    expect{find('td', text: post1.title, wait: 10)}.to_not raise_error
    expect{find('td', text: post2.title, wait: 10)}.to_not raise_error
    expect{find('td', text: post3.title, wait: 10)}.to_not raise_error

    post1.destroy
    post2.destroy

    expect{find('td', text: post1.title)}.to raise_error Capybara::ElementNotFound
    expect{find('td', text: post2.title)}.to raise_error Capybara::ElementNotFound
    expect{find('td', text: post3.title)}.to_not raise_error
  end

  # see spec/internal/app/models/post.rb to view specified whitelisted attributes
  scenario 'User sees live changes (updates) of post records, but only changes from whitelisted authorised attributes', js: true do
    visit '/posts'

    execute_script("LiveRecord.helpers.loadRecords({ modelName: 'Post' });")

    post1_title_td = find('td', text: post1.title, wait: 10)
    post1_content_td = find('td', text: post1.content, wait: 10)
    post2_title_td = find('td', text: post2.title, wait: 10)
    post2_content_td = find('td', text: post2.content, wait: 10)
    post3_title_td = find('td', text: post3.title, wait: 10)
    post3_content_td = find('td', text: post3.content, wait: 10)

    post1.update!(title: 'post1newtitle', content: 'post1newcontent')
    post2.update!(title: 'post2newtitle', content: 'post2newcontent')
    post3.update!(title: 'post3newtitle', content: 'post3newcontent')

    expect(post1_title_td).to have_content('post1newtitle', wait: 10)
    expect(post1_content_td).to_not have_content('post1newcontent')
    expect(post2_title_td).to have_content('post2newtitle', wait: 10)
    expect(post2_content_td).to_not have_content('post2newcontent')
    expect(post3_title_td).to have_content('post3newtitle', wait: 10)
    expect(post3_content_td).to_not have_content('post3newcontent')
  end

  scenario 'JS-Client can access Model associations record objects in its current store', js: true do
    visit '/posts'

    execute_script(
      <<-eos
      LiveRecord.helpers.loadRecords({ modelName: 'Post' });
      LiveRecord.helpers.loadRecords({ modelName: 'User', url: '#{users_path}' });
      eos
    )

    # let's wait for all records first before checking correct associations
    wait before: -> { evaluate_script('Object.keys( LiveRecord.Model.all.User.all ).length') }, becomes: -> (value) { value == users.size }, duration: 10.seconds
    expect(evaluate_script('Object.keys( LiveRecord.Model.all.User.all ).length')).to eq users.size
    wait before: -> { evaluate_script('Object.keys( LiveRecord.Model.all.Post.all ).length') }, becomes: -> (value) { value == posts.size }, duration: 10.seconds
    expect(evaluate_script('Object.keys( LiveRecord.Model.all.Post.all ).length')).to eq posts.size

    # users should have correct associated posts
    expect(evaluate_script(
      <<-eos
      LiveRecord.Model.all.User.all[#{user1.id}].posts().map(
        function(post) { return post.id() }
      )
      eos
    )).to eq user1.posts.pluck(:id)

    expect(evaluate_script(
      <<-eos
      LiveRecord.Model.all.User.all[#{user2.id}].posts().map(
        function(post) { return post.id() }
      )
      eos
    )).to eq user2.posts.pluck(:id)

    # posts should belong to correct associated user
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post1.id}].user().id()")).to eq post1.user.id
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post2.id}].user().id()")).to eq post2.user.id
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post3.id}].user()")).to eq nil
  end

  scenario 'JS-Client receives live new (create) post records where specified "conditions" matched', js: true do
    visit '/posts'

    execute_script("LiveRecord.Model.all.Post.subscribe({ where: { is_enabled_eq: true }});")

    sleep(1)

    post4 = create(:post, is_enabled: true)
    post5 = create(:post, is_enabled: false)
    post6 = create(:post, is_enabled: true)

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined") }, becomes: -> (value) { value == true }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined")).to be true

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post6.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post6.id}] == undefined")).to be false
  end

  scenario 'JS-Client receives live new (create) post records where only considered "conditions" are the whitelisted authorised attributes', js: true do
    visit '/posts'

    execute_script("LiveRecord.Model.all.Post.subscribe({ where: { is_enabled_eq: true, content_eq: 'somecontent' }});")

    sleep(1)

    # because `content` is not whitelisted in models/post.rb, therefore the `content` condition is disregarded from above
    post4 = create(:post, is_enabled: true, content: 'somecontent')
    post5 = create(:post, is_enabled: true, content: 'contentisnotwhitelistedthereforewontbeconsidered')

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined")).to be false
  end

  # see spec/internal/app/models/post.rb to view specified whitelisted attributes
  scenario 'JS-Client receives live new (create) post records having only the whitelisted authorised attributes', js: true do
    visit '/posts'

    execute_script("LiveRecord.Model.all.Post.subscribe();")

    sleep(1)

    post4 = create(:post, is_enabled: true, title: 'sometitle', content: 'somecontent')

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined")).to be false
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].title()")).to eq post4.title
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].attributes.content")).to eq nil
  end

  scenario 'JS-Client receives live autoloaded (create or update) post records where specified "conditions" matched', js: true do
    visit '/posts'

    # prepopulate
    disabled_post_that_will_be_enabled = create(:post, is_enabled: false)

    execute_script("LiveRecord.Model.all.Post.autoload({ where: { is_enabled_eq: true }});")

    sleep(1)

    disabled_post = create(:post, is_enabled: false)
    enabled_post = create(:post, is_enabled: true)

    sleep(5)

    disabled_post_that_will_be_enabled.update!(is_enabled: true)

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{disabled_post.id}] == undefined") }, becomes: -> (value) { value == true }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{disabled_post.id}] == undefined")).to be true

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{enabled_post.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{enabled_post.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{disabled_post_that_will_be_enabled.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{disabled_post_that_will_be_enabled.id}] == undefined")).to be false
  end

  scenario 'JS-Client receives live autoloaded (create or update) post records where only considered "conditions" are the whitelisted authorised attributes', js: true do
    visit '/posts'

    # prepopulate
    updated_post1 = create(:post, is_enabled: false, content: 'somecontent')
    updated_post2 = create(:post, is_enabled: false, content: 'contentisnotwhitelistedthereforewontbeconsidered')

    execute_script("LiveRecord.Model.all.Post.autoload({ where: { is_enabled_eq: true, content_eq: 'somecontent' }});")

    sleep(1)

    # because `content` is not whitelisted in models/post.rb, therefore the `content` condition is disregarded from above
    created_post1 = create(:post, is_enabled: true, content: 'somecontent')
    created_post2 = create(:post, is_enabled: true, content: 'contentisnotwhitelistedthereforewontbeconsidered')
    updated_post1.update!(is_enabled: true)
    updated_post2.update!(is_enabled: true)

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{created_post1.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{created_post1.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{created_post2.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{created_post2.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post1.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post1.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post2.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post2.id}] == undefined")).to be false
  end

  # see spec/internal/app/models/post.rb to view specified whitelisted attributes
  scenario 'JS-Client receives live autoloaded (create or update) post records having only the whitelisted authorised attributes', js: true do
    visit '/posts'

    # prepopulate
    updated_post = create(:post, is_enabled: true, title: 'sometitle', content: 'somecontent')

    execute_script("LiveRecord.Model.all.Post.autoload();")

    sleep(1)

    created_post = create(:post, is_enabled: true, title: 'sometitle', content: 'somecontent')
    updated_post = create(:post, is_enabled: false, title: 'sometitle', content: 'somecontent')

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{created_post.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{created_post.id}] == undefined")).to be false
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{created_post.id}].title()")).to eq created_post.title
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{created_post.id}].attributes.content")).to eq nil

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post.id}] == undefined")).to be false
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post.id}].title()")).to eq updated_post.title
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{updated_post.id}].attributes.content")).to eq nil
  end

  scenario 'JS-Client should not have shared callbacks for those callbacks defined only for a particular post record', js: true do
    visit '/posts'

    execute_script("LiveRecord.helpers.loadRecords({ modelName: 'Post' });")

    # wait first for all posts to be loaded
    wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
    expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

    execute_script(
      <<-eos
      var post1 = LiveRecord.Model.all.Post.all[#{post1.id}];
      var someCallbackFunction = function() {};
      post1.addCallback('after:create', someCallbackFunction);
      eos
    )

    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post2.id}]._callbacks['after:create'].length")).to eq 0
  end

  scenario 'JS-Client should receive response :forbidden error when using `subscribe()` but that the current_user is forbidden to do so', js: true do
    visit '/posts'

    execute_script("LiveRecord.Model.all.Post.subscribe();")

    expect_any_instance_of(LiveRecord::BaseChannel).to(
      receive(:respond_with_error).with(:forbidden, 'You do not have privileges to query').once
    )

    execute_script(
      <<-eos
      LiveRecord.Model.all.User.subscribe();
      eos
    )

    sleep(5)
  end

  scenario 'JS-Client can access defined belongsTo() and hasMany() associations', js: true do
    # prepopulate
    category_that_do_not_have_posts = create(:category)
    category_that_has_posts = create(:category)
    category_that_has_posts.tap do |category|
      create(:post, category: category)
      create(:post, category: category)
    end
    user_that_do_not_have_posts = create(:user)
    user_that_have_posts = create(:user)
    user_that_have_posts.tap do |user|
      create(:post, user: user)
      create(:post, user: user)
    end
    post_that_do_not_belong_to_user_nor_category = create(:post, user: nil, category: nil)
    post_that_belongs_to_user_but_not_category = create(:post, user: create(:user), category: nil)
    post_that_belongs_to_category_but_not_user = create(:post, category: create(:category), user: nil)
    post_that_belongs_to_both_category_and_user = create(:post, category: create(:category), user: create(:user))

    visit '/posts'

    execute_script(
      <<-eos
      LiveRecord.Model.all.Post.autoload({reload: true});
      LiveRecord.Model.all.User.autoload({reload: true});
      LiveRecord.Model.all.Category.autoload({reload: true});
      eos
    )

    'wait first for all records to be loaded'.tap do
      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.User.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.User.all ).length")).to be User.all.count

      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Category.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.Category.all ).length")).to be Category.all.count
    end

    'now check if associations are correct / matching'.tap do
      expect(evaluate_script(
        "LiveRecord.Model.all.Category.all[#{category_that_do_not_have_posts.id}].posts().map(function(post) {return post.id()})"
      )).to eq category_that_do_not_have_posts.posts.pluck(:id)

      expect(evaluate_script(
        "LiveRecord.Model.all.Category.all[#{category_that_has_posts.id}].posts().map(function(post) {return post.id()})"
      )).to eq category_that_has_posts.posts.pluck(:id)

      expect(evaluate_script(
        "LiveRecord.Model.all.User.all[#{user_that_do_not_have_posts.id}].posts().map(function(post) {return post.id()})"
      )).to eq user_that_do_not_have_posts.posts.pluck(:id)

      expect(evaluate_script(
        "LiveRecord.Model.all.User.all[#{user_that_have_posts.id}].posts().map(function(post) {return post.id()})"
      )).to eq user_that_have_posts.posts.pluck(:id)

      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_do_not_belong_to_user_nor_category.id}].user()"
      )).to eq nil
      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_do_not_belong_to_user_nor_category.id}].category()"
      )).to eq nil

      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_user_but_not_category.id}].user().id()"
      )).to eq post_that_belongs_to_user_but_not_category.user.id
      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_user_but_not_category.id}].category()"
      )).to eq nil

      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_category_but_not_user.id}].category().id()"
      )).to eq post_that_belongs_to_category_but_not_user.category.id
      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_category_but_not_user.id}].user()"
      )).to eq nil

      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_both_category_and_user.id}].category().id()"
      )).to eq post_that_belongs_to_both_category_and_user.category.id
      expect(evaluate_script(
        "LiveRecord.Model.all.Post.all[#{post_that_belongs_to_both_category_and_user.id}].user().id()"
      )).to eq post_that_belongs_to_both_category_and_user.user.id
    end
  end

  # see spec/internal/app/models/post.rb to view specified whitelisted attributes
  context 'when client got disconnected, and then reconnected' do
    scenario 'JS-Client resyncs stale records', js: true do
      post_that_will_be_updated_while_disconnected_1 = create(:post, is_enabled: true)
      post_that_will_be_updated_while_disconnected_2 = create(:post, is_enabled: true)

      visit '/posts'

      execute_script(
        <<-eos
        LiveRecord.helpers.loadRecords({ modelName: 'Post' });
        LiveRecord.Model.all.Post.subscribe();
        eos
      )

      # wait first for all posts to be loaded
      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

      Thread.new do
        sleep(2)

        # temporarily stop all current changes_channel connections
        ObjectSpace.each_object(LiveRecord::ChangesChannel) do |changes_channel|
          changes_channel.connection.close
        end

        # then we update records while disconnected
        post_that_will_be_updated_while_disconnected_1.update!(title: 'newtitle')
        post_that_will_be_updated_while_disconnected_2.update!(title: 'newtitle')
      end

      disconnection_time = 10
      sleep(disconnection_time)

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_1.id}] == undefined") }, becomes: -> (value) { value == false }, duration: 10.seconds
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_1.id}].title()")).to eq 'newtitle'

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_2.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_2.id}].title()")).to eq 'newtitle'
    end

    scenario 'JS-Client receives all post records created (matching the conditions) during the time it got disconnected', js: true do
      visit '/posts'

      post_created_before_disconnection = nil
      post_created_while_disconnected_1 = nil
      post_created_while_disconnected_2 = nil
      post_created_while_disconnected_but_does_not_match = nil

      # this needs to be before execute_script, otherwise it gets loaded by the subscription
      Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) - 30.seconds) do
        post_created_before_disconnection = create(:post, is_enabled: true)
      end

      execute_script("LiveRecord.Model.all.Post.subscribe({where: {is_enabled_eq: true}});")

      sleep(1)

      Thread.new do
        sleep(2)

        # temporarily stop all current publication_channel connections
        ObjectSpace.each_object(LiveRecord::PublicationsChannel) do |publication_channel|
          publication_channel.connection.close
        end

        # then we create records while disconnected
        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 30.seconds) do
          post_created_while_disconnected_1 = create(:post, is_enabled: true)
        end

        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours) do
          post_created_while_disconnected_2 = create(:post, is_enabled: true)
        end

        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours) do
          post_created_while_disconnected_but_does_not_match = create(:post, is_enabled: false)
        end
      end

      disconnection_time = 10
      sleep(disconnection_time)

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined") }, becomes: -> (value) { value == false }, duration: 10.seconds
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_but_does_not_match.id}] == undefined") }, becomes: -> (value) { value == true }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_but_does_not_match.id}] == undefined")).to be true

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined")).to be true
    end

    scenario 'JS-Client receives all post records created/updated (matching the conditions), during the time it got disconnected', js: true do
      post_created_before_disconnection = nil
      post_created_while_disconnected_1 = nil
      post_created_while_disconnected_2 = nil
      post_created_while_disconnected_but_does_not_match = nil

      # prepopulate before loading of page/script
      post_updated_before_disconnection = create(:post, is_enabled: false)
      post_updated_while_disconnected_1 = create(:post, is_enabled: false)
      post_updated_while_disconnected_2 = create(:post, is_enabled: false)
      post_updated_while_disconnected_but_does_not_match = create(:post, is_enabled: true)

      # this needs to be before execute_script, otherwise it gets loaded by the subscription
      Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) - 30.seconds) do
        post_created_before_disconnection = create(:post, is_enabled: true)
        post_updated_before_disconnection.update!(is_enabled: true)
      end

      visit '/posts'

      execute_script("LiveRecord.Model.all.Post.autoload({where: {is_enabled_eq: true}});")

      sleep(1)

      Thread.new do
        sleep(2)

        # temporarily stop all current autoloads_channel connections
        ObjectSpace.each_object(LiveRecord::AutoloadsChannel) do |autoloads_channel|
          autoloads_channel.connection.close
        end

        # then we create/update records while disconnected
        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 30.seconds) do
          post_created_while_disconnected_1 = create(:post, is_enabled: true)
          post_updated_while_disconnected_1.update!(is_enabled: true)
        end

        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours) do
          post_created_while_disconnected_2 = create(:post, is_enabled: true)
          post_updated_while_disconnected_2.update!(is_enabled: true)
        end

        Timecop.freeze((DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours) do
          post_created_while_disconnected_but_does_not_match = create(:post, is_enabled: false, created_at: (DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours)
          post_updated_while_disconnected_but_does_not_match.update!(is_enabled: false)
        end
      end

      disconnection_time = 10
      sleep(disconnection_time)

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined") }, becomes: -> (value) { value == false }, duration: 10.seconds
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_but_does_not_match.id}] == undefined") }, becomes: -> (value) { value == true }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_but_does_not_match.id}] == undefined")).to be true

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined")).to be true
    end
  end
end
