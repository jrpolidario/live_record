require 'rails_helper'

RSpec.feature 'LiveRecord Syncing', type: :feature do
  let(:post1) { create(:post) }
  let(:post2) { create(:post) }
  let(:post3) { create(:post) }
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

  # see spec/internal/app/views/posts/index.html.erb to see the subscribe "conditions"
  scenario 'JS-Client receives live new (create) post records where specified "conditions" matched', js: true do
    visit '/posts'

    Thread.new do
      sleep(5)
    end.join

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

    Thread.new do
      sleep(5)
    end.join

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
  scenario 'JS-Client receives live new (create) post records having only the whitelisted authorised attributes', js: true, focus: true do
    visit '/posts'

    Thread.new do
      sleep(5)
    end.join

    post4 = create(:post, is_enabled: true, title: 'sometitle', content: 'somecontent')
    
    wait before: -> { evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}] == undefined") }, becomes: -> (value) { value == false }
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].title()")).to eq post4.title
    expect(evaluate_script("LiveRecord.Model.all.Post.all[#{post4.id}].content()")).to eq nil
  end
end
