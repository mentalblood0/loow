require "./Command.cr"

module Wool
  abstract class Convertible
    abstract def convert : Array(Command)

    class Batch < Convertible
      include YAML::Serializable
      include YAML::Serializable::Strict

      class AddText
        include YAML::Serializable
        include YAML::Serializable::Strict

        getter id : String? = nil
        getter text : String
      end

      class AddRelation
        include YAML::Serializable
        include YAML::Serializable::Strict

        getter id : String? = nil
        getter type : String
        getter from : String
        getter to : String
      end

      class AddTags
        include YAML::Serializable
        include YAML::Serializable::Strict

        getter to : String
        getter tags : Array(String)
      end

      alias Element = AddText |
                      AddRelation |
                      AddTags
      getter elements : Array(Element)

      def convert : Array(Command)
        s2i = Hash(String, Id).new
        @elements.map do |e|
          case e
          when AddText
            r = Command::Add.new({c: e.text})
            s2i[e.id.not_nil!] = Id.from_content r.args[:c] if e.id
          when AddRelation
            r = Command::Add.new({c: {from: s2i[e.from], to: s2i[e.to], type: e.type}})
            s2i[e.id.not_nil!] = Id.from_content r.args[:c] if e.id
          when AddTags
            r = Command::AddTags.new({id: s2i[e.to], tags: e.tags})
          end
          r.not_nil!
        end
      end
    end
  end
end
