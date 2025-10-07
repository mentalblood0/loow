require "./common.cr"
require "./Sweater"

module Wool
  abstract class Command(T)
    mserializable

    getter action : String

    mjyd action, add, delete, add_tags, delete_tags, get, get_relations, get_by_tags

    abstract def exec(s : T)

    dc Sweater, add, {c: Content}, begin
      s.add **@args
    end

    dc Sweater, delete, {id: Id}, begin
      s.delete **@args
    end

    dc Sweater, add_tags, {id: Id, tags: Set(Tag)}, begin
      s.add **@args
    end

    dc Sweater, delete_tags, {id: Id, tags: Set(Tag)}, begin
      s.delete **@args
    end

    dc Sweater, get, {id: Id}, begin
      s.get **@args
    end

    dc Sweater, get_relations, {id: Id}, begin
      s.get_relations **@args
    end

    dc Sweater, get_by_tags, {present: Set(Tag), absent: Set(Tag), from: Id?, limit: UInt64}, begin
      s.get **@args
    end
  end
end
