require "yaml"
require "json"

require "trove"
require "xxhash128"

require "./Id"

macro mserializable
  include YAML::Serializable
  include YAML::Serializable::Strict
  include JSON::Serializable
  include JSON::Serializable::Strict
end

module Wool
  class Exception < Exception
  end

  def self.typed_json(v)
    JSON.parse ({"type" => v.class.name, v.class.name => v}).to_json
  end

  class Mention
    mserializable

    getter what : Id
    getter where : Id

    getter id : Id { Id.from_serializable self }

    def initialize(@what, @where)
    end
  end

  class Relation
    mserializable

    class Type
      mserializable

      @@pattern = /\w+(?: ?\w)*/

      getter name : String

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

    getter id : Id { Id.from_serializable self }
    getter mentions : Set(Mention) { Set(Mention).new }

    def initialize(@from, @type, @to)
    end
  end

  class Text
    mserializable

    @@pattern = /(?:\w|\d)+(?: ?(?:\w|\d|,|-|:))*/

    getter value : String

    getter id : Id { Id.from_serializable self }
    getter mentions : Set(Mention) { (@value.scan /{([^{}]+)}/).map { |m| Mention.new what: id, where: Id.from_string m[1] } }

    def initialize(@value)
      after_initialize
    end

    def after_initialize
      raise Exception.new "Text \"#{@value}\" has invalid pattern, correct pattern is #{@@pattern}" unless @value.match @@pattern
    end
  end

  alias Content = Relation | Text

  class Tag
    mserializable

    @@pattern = /(?:\w|\d|_)+/

    getter name : String

    def initialize(@name)
      after_initialize
    end

    def after_initialize
      raise Exception.new "Tag \"#{@name}\" has invalid pattern, correct pattern is #{@@pattern}" unless @name.match @@pattern
    end
  end

  class Thesis
    mserializable

    getter content : Content
    getter tags : Set(Tag)

    getter id : Id { @content.id }

    def initialize(@content, @tags = Set(Tag).new)
    end
  end

  class Sweater
    mserializable

    getter relations_types : Set(Relation::Type)
    getter chest : Trove::Chest

    def add(c : Content)
      raise Exception.new "Content #{c} already exists" if @chest.has_key! c.id, "type"

      case c.value
      when Text
        c.mentions { |m| @chest.set m.id, "", typed_json m }
      when Relation
        raise Exception.new "Relation type \"#{c.type}\" is not allowed in this Sweater" unless @relations_types.includes? c[:type]
        raise Exception.new "No \"from\" id #{c.from.to_string} for relation" unless chest.has_key! c.from, "type"
        raise Exception.new "No \"to\" id #{c.to.to_string} for relation" unless chest.has_key! c.to, "type"
      end

      @chest.set id, "", typed_json Thesis.new c
      id
    end

    def add(id : Id, tags : Set(Tag))
      @chest.transaction { |tx| tags.each { |t| @chest.set! id, "thesis.tags.#{t.name}", JSON::Any.new nil } }
    end

    def delete(id : Id, tags : Set(Tag))
      @chest.transaction do |tx|
        tags.each { |t| @chest.delete! id, "thesis.tags.#{t.name}" }
      end
    end

    def get(id : Id) : Thesis?
      r = (@chest.get id).not_nil!["thesis"] rescue return nil
      {content:   (Content.from_json r["content"].to_json),
       relations: {from: (Set.new @chest.where({"thesis.content.value.from" => id.to_string})),
                   to: (Set.new @chest.where({"thesis.content.value.to" => id.to_string}))},
       tags: ((Set(String).new r["tags"].as_h.keys rescue Set(String).new))}
    end

    def get(c : Content) : Thesis?
      get Id.from_content c
    end

    def delete(id : Id)
      @chest.transaction do |tx|
        tx.where({"thesis.content.#{p}" => id.to_string}) do |oid|
          tx.delete oid
        end
      end
    end

    def get(present : Array(String), absent : Array(String) = [] of String, from : Id? = nil, &)
      @chest.where(
        (Hash.zip present.map { |t| "tags.#{t}" }, (Array.new(present.size) { nil })),
        (Hash.zip absent.map { |t| "tags.#{t}" }, (Array.new(absent.size) { nil })),
        from) { |o| yield o }
    end

    def get(present : Array(String), absent : Array(String) = [] of String, from : Id? = nil, limit : UInt64 = UInt64::MAX)
      r = [] of Id
      get(present, absent, from) do |o|
        break if r.size == limit
        r << o
      end
      r
    end
  end
end
