require "yaml"

require "./Sweater"

module Wool
  abstract struct Command
    include YAML::Serializable
    include YAML::Serializable::Strict

    getter action : String
    use_yaml_discriminator "action", {add:         Add,
                                      delete:      Delete,
                                      add_tags:    AddTags,
                                      delete_tags: DeleteTags,
                                      get:         Get,
                                      get_by_tags: GetByTags}

    def initialize(@action)
    end

    abstract def exec(s : Sweater)

    struct Add < Command
      getter args : {c: Content}

      def initialize(@args)
        super("add")
      end

      def exec(s : Sweater)
        s.add **@args
      end
    end

    struct Delete < Command
      getter args : {id: Id}

      def initialize(@args)
        super("delete")
      end

      def exec(s : Sweater)
        s.delete **@args
      end
    end

    struct AddTags < Command
      getter args : {id: Id, tags: Array(String)}

      def initialize(@args)
        super("add_tags")
      end

      def exec(s : Sweater)
        s.add **@args
      end
    end

    struct DeleteTags < Command
      getter args : {id: Id, tags: Array(String)}

      def initialize(@args)
        super("delete_tags")
      end

      def exec(s : Sweater)
        s.delete **@args
      end
    end

    struct Get < Command
      getter args : {id: Id}

      def initialize(@args)
        super("get")
      end

      def exec(s : Sweater)
        s.get **@args
      end
    end

    struct GetIds < Command
      getter args : {present: Array(String), absent: Array(String), limit: UInt32, from: Id?}

      def initialize(@args)
        super("get_by_tags")
      end

      def exec(s : Sweater)
        s.get **@args
      end
    end
  end
end
