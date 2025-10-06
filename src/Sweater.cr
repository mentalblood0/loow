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

    def add(c : Content) : Id
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

    def delete(id : Id) : Id
      @chest.transaction do |tx|
        ["from", "to"].each do |p|
          tx.where({"thesis.content.value.#{p}" => id.string}) { |ri| tx.delete ri }
        end
        tx.delete id
      end
      id
    end

    def add(id : Id, tags : Set(Tag)) : UInt32
      @chest.push id, "thesis.tags", tags.map { |t| JSON::Any.new t.name }
    end

    def delete(id : Id, tags : Set(Tag)) : UInt32
      @chest.transaction { |tx| tags.each { |t| tx.delete! id, "thesis.tags.#{tx.index id, "thesis.tags", t.name}" } }
      tags.size.to_u32
    end

    def get(id : Id) : Thesis?
      Wool.from_tj Thesis, (@chest.get id).not_nil! rescue nil
    end

    def get_relations(id : Id, &block : Thesis ->)
      ["from", "to"].each do |p|
        @chest.where({"thesis.content.#{p}" => id.string}) { |ri| yield Wool.from_tj Thesis, (@chest.get ri).not_nil! }
      end
    end

    def get_relations(id : Id) : Set(Thesis)
      r = Set(Thesis).new
      get_relations(id) { |re| r << re }
      r
    end

    def get(present : Set(Tag), absent : Set(Tag) = Set(Tag).new, from : Id? = nil, &block : Id ->)
      @chest.where(
        (Hash.zip Array.new(present.size) { "thesis.tags" }, present.map { |t| t.name }),
        (Hash.zip Array.new(absent.size) { "thesis.tags" }, absent.map { |t| t.name }),
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
