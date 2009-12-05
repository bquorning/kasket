require File.dirname(__FILE__) + '/helper'

class FindSomeTest < ActiveSupport::TestCase
  fixtures :blogs, :posts

  should_eventually "cache find(id, id) calls" do
    post1 = Post.first
    post2 = Post.last

    assert_nil(Rails.cache.read(post1.kasket_key))
    assert_nil(Rails.cache.read(post2.kasket_key))

    Post.find(post1.id, post2.id)

    assert(Rails.cache.read(post1.kasket_key))
    assert(Rails.cache.read(post2.kasket_key))
    Post.connection.expects(:select_all).never
    Post.find(post1.id, post2.id)
  end

  should_eventually "only lookup the records that are not in the cache" do
    post1 = Post.first
    post2 = Post.last
    assert_equal(post1, Post.find(post1.id))
    assert(Rails.cache.read(post1.kasket_key))
    assert_nil(Rails.cache.read(post2.kasket_key))

    Post.expects(:find_by_sql_without_kasket).with("SELECT * FROM \'posts\' WHERE (\'posts\'.\'id\' IN (#{post1.id},#{post2.id})) ").returns([post2])
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)

    Post.expects(:find_by_sql_without_kasket).never
    found_posts = Post.find(post1.id, post2.id)
    assert_equal([post1, post2].map(&:id).sort, found_posts.map(&:id).sort)
  end

  should_eventually "cache on index other than primary key" do
    blog = blogs(:a_blog)
    posts = Post.find_all_by_blog_id(blog.id)

    Post.expects(:find_by_sql_without_kasket).never

    assert_equal(posts, Post.find_all_by_blog_id(blog.id))
  end
end
