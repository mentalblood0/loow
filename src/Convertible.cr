require "./Command.cr"

module Wool
  abstract class Convertible
    abstract def convert : Array(Command)

    class Batch < Convertible
      include YAML::Serializable
      include YAML::Serializable::Strict

      alias AddText = String
      alias AddTextWId = {id: String, text: String}
      alias AddRelation = {from: String, to: String, type: Wool::Type}
      alias AddRelationWId = {id: String, from: String, to: String, type: Wool::Type}
      alias AddTags = {to: String, tags: Array(String)}
      alias Element = AddText |
                      AddTextWId |
                      AddRelation |
                      AddRelationWId |
                      AddTags
      getter elements : Array(Element)

      def convert : Array(Command)
        s2i = Hash(String, Id).new
        @elements.map do |e|
          puts "#{e} #{s2i}"
          case e
          when AddText
            r = Command::Add.new({c: e})
          when AddTextWId
            r = Command::Add.new({c: e[:text]})
            s2i[e[:id]] = Id.from_content r.args[:c]
          when AddRelation
            r = Command::Add.new({c: {from: s2i[e[:from]], to: s2i[e[:to]], type: e[:type]}})
          when AddRelationWId
            r = Command::Add.new({c: {from: s2i[e[:from]], to: s2i[e[:to]], type: e[:type]}})
            s2i[e[:id]] = Id.from_content r.args[:c]
          when AddTags
            r = Command::AddTags.new({id: s2i[e[:to]], tags: e[:tags]})
          end
          r.not_nil!
        end
      end
    end
  end
end
