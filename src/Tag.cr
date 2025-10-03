require "./common.cr"
require "./exceptions"

module Wool
  class Tag
    mserializable

    @@pattern = /(?:\w|\d|_)+/

    getter name : String

    def_equals_and_hash @name

    def initialize(@name)
      after_initialize
    end

    def after_initialize
      raise Exception.new "Tag \"#{@name}\" has invalid pattern, correct pattern is #{@@pattern}" unless @name.match @@pattern
    end
  end
end
