require 'rails_helper'

RSpec.feature 'LiveRecord Updating', type: :feature do
  let(:post) { create(:post) }

  context 'without validation errors' do
    let(:new_post_title) { 'post1newtitle' }

    scenario 'post is updated', js: true do
      visit "/posts/#{post.id}/edit"

      execute_script(
        <<-eos
        post = new LiveRecord.Model.all.Post({ id: #{post.id} })
        post.store();
        post.update({
          title: '#{new_post_title}'
        })
        eos
      )

      sleep 3

      expect(post.reload.title).to eq new_post_title
    end
  end

  context 'with validation errors', :focus do
    let(:new_post_title) { '' }

    scenario 'post is not updated, and responds with an invalid error', js: true do
      expect_any_instance_of(LiveRecord::ChangesChannel).to receive(:respond_with_error).with(:invalid, { title: ["can't be blank"] }).and_call_original

      visit "/posts/#{post.id}/edit"

      execute_script(
        <<-eos
        post = new LiveRecord.Model.all.Post({ id: #{post.id} })
        post.store();
        post.update({
          title: '#{new_post_title}'
        })
        eos
      )

      sleep 3

      expect(post.reload.title).to eq post.title
      browser_console_log = page.driver.browser.manage.logs.get(:browser).last.message
      expect(browser_console_log).to include 'LiveRecord Response Error'
    end
  end
end
