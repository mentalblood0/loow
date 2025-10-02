require "./Mention"

module Wool
  class Text
    mserializable

    @@pattern = /(?:\w|\d)+(?: ?(?:\w|\d|,|-|:))*/

    getter value : String

    getter id : Id { Id.from_serializable self }
    getter mentions : Set(Mention) { Set.new (@value.scan /{([^{}]+)}/).map { |m| Mention.new what: id, where: Id.from_string m[1] } }

    def initialize(@value)
      after_initialize
    end

    def after_initialize
      raise Exception.new "Text \"#{@value}\" has invalid pattern, correct pattern is #{@@pattern}" unless @value.match @@pattern
    end
  end
end
