require "./Sweater"

module Wool
  abstract struct Command
    include YAML::Serializable
    include YAML::Serializable::Strict

    macro myd(d, *nn)
      use_yaml_discriminator "{{d}}", {
        {% for n in nn %}
          {{n}}: {{n.stringify.camelcase.id}},
        {% end %}
      }
    end

    macro dc(n, a, b)
      struct {{n.stringify.camelcase.id}} < Command
        include YAML::Serializable
        include YAML::Serializable::Strict

        getter args : {{a}}

        def initialize(@args)
          @action = "{{n}}"
        end

        def exec(s : Sweater)
          {{b}}
        end
      end
    end

    getter action : String

    myd action, add, delete, add_tags, delete_tags, get, get_by_content, get_by_tags

    abstract def exec(s : Sweater)

    dc add, {c: Content}, begin
      s.add **@args
    end

    dc delete, {id: Id}, begin
      s.delete **@args
    end

    dc add_tags, {id: Id, tags: Array(String)}, begin
      s.add **@args
    end

    dc delete_tags, {id: Id, tags: Array(String)}, begin
      s.delete **@args
    end

    dc get, {id: Id}, begin
      s.get **@args
    end

    dc get_by_content, {c: Content}, begin
      s.get **@args
    end

    dc get_by_tags, {present: Array(String), absent: Array(String), from: Id?, limit: UInt64}, begin
      s.get **@args
    end
  end
end
