require 'rails_helper'

RSpec.feature 'LiveRecord Syncing', type: :feature do
	let(:post1) { create(:post) }
	let(:post2) { create(:post) }
	let!(:posts) { [post1, post2] }

  scenario 'User sees live changes of a post record' do
    visit '/posts'

    node = find('td', text: post1.title)

    post1.update(title: 'newtitle')

    expect(node1).to have_content('newtitle')
  end
end