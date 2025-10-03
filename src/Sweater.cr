require "yaml"
require "json"

require "trove"
require "xxhash128"

require "./common"
require "./Relation"
require "./Thesis"

module Wool
  class Sweater
    mserializable

    getter relations_types : Set(Relation::Type)
    getter chest : Trove::Chest

    def add(c : Content)
      @chest.transaction do |tx|
        raise Exception.new "Content #{c} already exists" if @chest.has_key! c.id, "type"

        case c
        when Text
          c.mentions.map { |m| tx.set m.id, "", Wool.to_tj m }
        when Relation
          raise Exception.new "Relation type #{c.type.to_json} is not allowed in this Sweater, allowed types are #{(relations_types.map &.to_json).join ", "}" unless @relations_types.includes? c.type
          raise Exception.new "No \"from\" id \"#{c.from.string}\" for relation" unless tx.has_key! c.from, "type"
          raise Exception.new "No \"to\" id \"#{c.to.string}\" for relation" unless tx.has_key! c.to, "type"
        end

        th = Thesis.new c
        tx.set c.id, "", Wool.to_tj th
      end
      c.id
    end

    def delete(id : Id)
      @chest.transaction do |tx|
        ["from", "to"].each do |p|
          tx.where({"thesis.content.value.#{p}" => id.string}) { |ri| tx.delete ri }
        end
        tx.delete id
      end
    end

    def add(id : Id, tags : Set(Tag))
      @chest.transaction { |tx| tags.each { |t| tx.set! id, "thesis.tags.#{t.name}", JSON::Any.new nil } }
    end

    def delete(id : Id, tags : Set(Tag))
      @chest.transaction { |tx| tags.each { |t| tx.delete! id, "thesis.tags.#{t.name}" } }
    end

    def get(id : Id) : Thesis?
      Wool.from_tj Thesis, (@chest.get id).not_nil! rescue nil
    end

    def get_related(id : Id, &block : Thesis ->)
      ["from", "to"].each do |p|
        @chest.where({"thesis.content.#{p}" => id.string}) { |ri| yield Wool.from_tj Thesis, (@chest.get ri).not_nil! }
      end
    end

    def get_related(id : Id) : Set(Thesis)
      r = Set(Thesis).new
      get_related(id) { |re| r << re }
      r
    end

    def get(present : Set(Tag), absent : Set(Tag) = Set(Tag).new, from : Id? = nil, &block : Id ->)
      @chest.where(
        (Hash.zip present.map { |t| "thesis.tags.#{t}" }, Array.new(present.size) { nil }),
        (Hash.zip absent.map { |t| "thesis.tags.#{t}" }, Array.new(absent.size) { nil }),
        from) { |i| yield i }
    end

    def get(present : Set(Tag), absent : Set(Tag) = Set(Tag).new, from : Id? = nil, limit : UInt64 = UInt64::MAX) : Array(Id)
      r = [] of Id
      get(present, absent, from) do |o|
        break if r.size == limit
        r << o
      end
      r
    end
  end
end
