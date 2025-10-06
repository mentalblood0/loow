require "./Command"

module Wool
  abstract class Convertible(T)
    abstract def convert(&block : T ->) : Nil

    def convert
      r = Array(T).new
      convert { |t| r << t }
      r
    end

    class Batch < Convertible(Command(Sweater))
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

      def initialize(@elements)
      end

      def convert(&block : T ->) : Nil
        s2i = Hash(String, Id).new
        @elements.each do |e|
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
          yield r.not_nil!
        end
      end
    end
  end
end
