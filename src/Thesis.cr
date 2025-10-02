require "./Content"
require "./Tag"

module Wool
  class Thesis
    mserializable

    getter content : Content
    getter tags : Set(Tag)

    getter id : Id { @content.id }

    def initialize(@content, @tags = Set(Tag).new)
    end
  end
end
