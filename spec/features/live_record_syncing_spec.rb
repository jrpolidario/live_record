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

  # see spec/internal/app/views/posts/index.html.erb to see the subscribe "conditions"
  scenario 'JS-Client receives live new (create) post records where specified "conditions" matched', js: true do
    visit '/posts'

    # wait first for all posts to be loaded
    wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
    expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

    post4 = create(:post, id: 98, is_enabled: true)
    post5 = create(:post, id: 99, is_enabled: false)

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined")).to be false

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined") }, becomes: -> (value) { value == true }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post5.id}] == undefined")).to be true
  end

  # see spec/internal/app/views/posts/index.html.erb to see the subscribe "conditions"
  scenario 'JS-Client receives live new (create) post records where only considered "conditions" are the whitelisted authorised attributes', js: true do
    visit '/posts'

    # wait first for all posts to be loaded
    wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
    expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

    # in index.html.erb:
    # LiveRecord.Model.all.Post.subscribe({ where: { is_enabled: true, content: 'somecontent' }});
    # because `content` is not whitelisted, therefore the `content` condition above is disregarded
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

    # wait first for all posts to be loaded
    wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
    expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

    post4 = create(:post, is_enabled: true, title: 'sometitle', content: 'somecontent')

    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].title()")).to eq post4.title
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].content()")).to eq nil
  end

  scenario 'JS-Client should not have shared callbacks for those callbacks defined only for a particular post record', js: true do
    visit '/posts'

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

    # wait first for all posts to be loaded
    wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
    expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

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

  # see spec/internal/app/models/post.rb to view specified whitelisted attributes
  context 'when client got disconnected, and then reconnected' do
    scenario 'JS-Client resyncs stale records', js: true do
      post_that_will_be_updated_while_disconnected_1 = create(:post, is_enabled: true)
      post_that_will_be_updated_while_disconnected_2 = create(:post, is_enabled: true)

      visit '/posts'

      # wait first for all posts to be loaded
      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

      disconnection_time = 10 # seconds

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

      # LiveRecord.stop_all_streams
      sleep(disconnection_time)

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_1.id}] == undefined") }, becomes: -> (value) { value == false }, duration: 10.seconds
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_1.id}].title()")).to eq 'newtitle'

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_2.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_that_will_be_updated_while_disconnected_2.id}].title()")).to eq 'newtitle'
    end

    scenario 'JS-Client receives all post records created during the time it got disconnected', js: true do
      visit '/posts'

      # wait first for all posts to be loaded
      wait before: -> { evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length") }, becomes: -> (value) { value == Post.all.count }, duration: 10.seconds
      expect(evaluate_script("Object.keys( LiveRecord.Model.all.Post.all ).length")).to be Post.all.count

      disconnection_time = 10 # seconds

      post_created_before_disconnection = nil
      post_created_while_disconnected_1 = nil
      post_created_while_disconnected_2 = nil

      Thread.new do
        sleep(2)

        # temporarily stop all current publication_channel connections
        ObjectSpace.each_object(LiveRecord::PublicationsChannel) do |publication_channel|
          publication_channel.connection.close
        end

        # then we create records while disconnected
        post_created_while_disconnected_1 = create(:post, is_enabled: true, created_at: (DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 30.seconds)
        post_created_while_disconnected_2 = create(:post, is_enabled: true, created_at: (DateTime.now - LiveRecord.configuration.sync_record_buffer_time) + 99.hours)
        # we need to create this here, otherwise it will be loaded on the Page immediately by the .loadRecords() in JS
        post_created_before_disconnection = create(:post, is_enabled: true, created_at: (DateTime.now - LiveRecord.configuration.sync_record_buffer_time) - 30.seconds)
      end

      # LiveRecord.stop_all_streams
      sleep(disconnection_time)

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined") }, becomes: -> (value) { value == false }, duration: 10.seconds
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_1.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_while_disconnected_2.id}] == undefined")).to be false

      wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined") }, becomes: -> (value) { value == false }
      expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post_created_before_disconnection.id}] == undefined")).to be true
    end
  end
end
