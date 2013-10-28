require File.expand_path("helper", File.dirname(__FILE__))

module Nori
  class StringWithAttributes < String
  end

  class Unknown
  end
end

class VisitorTest < ActiveSupport::TestCase
  if arel?
    context Kasket::Visitor do
      should "build select id" do
        expected = {
          :attributes=>[[:id, "1"]],
          :from=>"posts",
          :index=>[:id],
          :key=>"#{Post.kasket_key_prefix}id=1"
        }
        assert_equal expected, Post.where(:id => 1).to_kasket_query
      end

      should "build from Nori::StringWithAttributes" do
        expected = {
          :attributes=>[[:id, "1"]],
          :from=>"posts",
          :index=>[:id],
          :key=>"#{Post.kasket_key_prefix}id=1"
        }
        assert_equal expected, Post.where(:id => Nori::StringWithAttributes.new("1")).to_kasket_query
      end

      should "notify on missing attribute" do
        ActiveRecord::Base.logger.expects(:info).with { |info| assert_includes info, "Kasket: Cannot visit unsupported class"; true }
        Post.where(:id => Nori::Unknown.new).to_kasket_query
      end
    end
  end
end
