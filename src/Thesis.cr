require "./Content"
require "./Tag"

module Wool
  module SetAsDict
    def self.from_json(parser : JSON::PullParser) : Set(Tag)
      r = Set(Tag).new
      parser.read_object do |k|
        r << Tag.new k
        parser.read_null
      end
      r
    end

    def self.to_json(value : Set(Tag), builder : JSON::Builder)
      builder.object do
        value.each do |t|
          builder.field(t.name, nil)
        end
      end
    end
  end

  class Thesis
    mserializable

    getter content : Content

    @[JSON::Field(converter: Wool::SetAsDict)]
    getter tags : Set(Tag) = Set(Tag).new

    def_equals_and_hash @content

    getter id : Id { @content.id }

    def initialize(@content, @tags = Set(Tag).new)
    end
  end
end
