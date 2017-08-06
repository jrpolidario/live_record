require 'rails_helper'

RSpec.feature 'LiveRecord Syncing', type: :feature do
	let(:post1) { create(:post) }
	let(:post2) { create(:post) }
	let!(:posts) { [post1, post2] }

  scenario 'User sees live changes of a post record', js: true do
    visit '/posts'

    node = find('td', text: post1.title)

    post1.update!(title: 'newtitle')

    # Thread.new do
    # 	byebug
    # end.join
    # while true do
    # 	sleep(0.)
    # end

    Timeout.timeout(Capybara.default_max_wait_time) do
	    active = page.evaluate_script('jQuery.active')
	    until active == 0
	      active = page.evaluate_script('jQuery.active')
	    end
	  end

    # puts page.evaluate_script("LiveRecord.Model.all.Post.all")

    message_data = { 'action' => 'update', 'attributes' => {'title' => 'newtitle'} }

    LiveRecordChannel.broadcast_to(post1, message_data)

    puts page.evaluate_script('LiveRecord.Model.all.Post.all[1].isSubscribed()')

    expect(node).to have_content('newtitle', wait: 60)
  end
end
