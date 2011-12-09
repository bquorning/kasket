require 'temping'

if Temping.respond_to?(:create)
  def create_model(name, &block)
    Temping.create(name, &block)
  end
else
  include Temping
end

create_model :comment do
  with_columns do |t|
    t.text     "body"
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  belongs_to :post
  has_one :author, :through => :post

  has_kasket_on :post_id
end

create_model :author do
  with_columns do |t|
    t.string "name"
  end

  has_many :posts

  has_kasket
end

create_model :post do
  with_columns do |t|
    t.string   "title"
    t.integer  "author_id"
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  belongs_to :blog
  belongs_to :author
  has_many :comments

  has_kasket
  has_kasket_on :title
  has_kasket_on :blog_id, :id

  def make_dirty!
    self.updated_at = Time.now
    self.connection.execute("UPDATE posts SET updated_at = '#{updated_at.utc.to_s(:db)}' WHERE id = #{id}")
  end

  kasket_dirty_methods :make_dirty!
end

create_model :blog do
  with_columns do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  has_many :posts
  has_many :comments, :through => :posts
end
