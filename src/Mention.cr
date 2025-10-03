require "./common"
require "./Id"

module Wool
  class Mention
    mserializable

    getter what : Id
    getter where : Id

    def_equals_and_hash @what, @where

    getter id : Id { Id.from_serializable self }

    def initialize(@what, @where)
    end
  end
end
