require "./Sweater"

module Wool
  abstract struct Command(T)
    mserializable

    macro mjyd(d, *nn)
      use_yaml_discriminator "{{d}}", {
        {% for n in nn %}
          {{n}}: {{n.stringify.camelcase.id}},
        {% end %}
      }
      use_json_discriminator "{{d}}", {
        {% for n in nn %}
          {{n}}: {{n.stringify.camelcase.id}},
        {% end %}
      }
    end

    macro dc(t, n, a, b)
      struct {{n.stringify.camelcase.id}} < Command({{t}})
        mserializable

        getter args : {{a}}

        def_equals_and_hash @action, @args

        def initialize(@args)
          @action = "{{n}}"
        end

        def exec(s : Sweater)
          {{b}}
        end
      end
    end

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
