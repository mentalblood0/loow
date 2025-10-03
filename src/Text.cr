require "./Mention"

module Wool
  class Text
    mserializable

    @@pattern = /(?:\w|\d)+(?: ?(?:\w|\d|,|-|:))*/

    getter value : String

    def_equals_and_hash @value

    getter id : Id { Id.from_serializable self }
    getter mentions : Set(Mention) { Set.new (@value.scan /{([^{}]+)}/).map { |m| Mention.new what: (Id.from_string m[1]), where: id } }

    def initialize(@value)
      after_initialize
    end

    def after_initialize
      raise Exception.new "Text \"#{@value}\" has invalid pattern, correct pattern is #{@@pattern}" unless @value.match @@pattern
    end
  end
end
