require "./Mention"

module Wool
  class Relation
    mserializable

    class Type
      mserializable

      @@pattern = /\w+(?: ?\w)*/

      getter name : String

      def_equals_and_hash @name

      def initialize(@name)
        after_initialize
      end

      def after_initialize
        raise Exception.new "Relation type \"#{@name}\" has invalid pattern, correct pattern is #{@@pattern}" unless @name.match @@pattern
      end
    end

    getter from : Id
    getter type : Type
    getter to : Id

    def_equals_and_hash @from, @type, @to

    getter id : Id { Id.from_serializable self }
    getter mentions : Set(Mention) { Set(Mention).new }

    def initialize(@from, @type, @to)
    end
  end
end
