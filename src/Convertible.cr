require "./Command"

module Wool
  abstract class Convertible
    abstract def convert : Array(Command)

    class Batch < Convertible
      mserializable

      class AddText
        mserializable

        getter id : String? = nil
        getter text : String
      end

      class AddRelation
        mserializable

        getter id : String? = nil
        getter type : String
        getter from : String
        getter to : String
      end

      class AddTags
        mserializable

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
            text = Text.new e.text.gsub /{[^{}]+}/ { |s| "{#{s2i[s[1..-2]].string}}" }
            r = Command::Add.new({c: text})
            s2i[e.id.not_nil!] = r.args[:c].id if e.id
          when AddRelation
            r = Command::Add.new({c: Relation.new from: s2i[e.from], to: s2i[e.to], type: Relation::Type.new e.type})
            s2i[e.id.not_nil!] = r.args[:c].id if e.id
          when AddTags
            r = Command::AddTags.new({id: s2i[e.to], tags: Set.new e.tags.map { |t| Tag.new t }})
          end
          r.not_nil!
        end
      end
    end
  end
end
