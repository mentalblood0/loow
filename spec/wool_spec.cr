require "spec"

require "../src/Command"
require "../src/Convertible"
require "../src/Graph"

rnd = Random.new 0

alias Config = {sweater: Wool::Sweater, graph: {dest: String, config: Wool::Graph::Config}, conversion: {src: String}}

describe Wool do
  config = Config.from_yaml File.read "spec/config.yml"
  sweater = config[:sweater]

  Spec.after_each do
    File.open config[:graph][:dest], "w" do |gio|
      g = Wool::Graph.new sweater, config[:graph][:config]
      g.write gio
    end
  end

  it "can handle large theses" do
    t = Wool::Text.new "B" * 1024 * 8
    id = sweater.add t
    (sweater.get id).not_nil!.content.should eq t
  end

  it "generative" do
    tt = {} of Wool::Id => Wool::Thesis
    i = 0
    until i == 100
      case rnd.rand 0..3
      when 0
        c = Wool::Text.new rnd.hex 17
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = Wool::Thesis.new c
      when 1
        c = Wool::Relation.new(
          from: (tt.sample rnd rescue next)[0],
          to: (tt.sample rnd rescue next)[0],
          type: sweater.relations_types.sample rnd
        )
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = Wool::Thesis.new c
      when 2
        id = (tt.sample rnd rescue next)[0]
        tags = Set.new Array.new (rnd.rand 1..8) { Wool::Tag.new "t" + rnd.hex 1 }
        Wool::Command::AddTags.new({id: id, tags: tags}).exec sweater
        tt[id].tags.concat tags
      when 3
        id = (tt.sample rnd rescue next)[0]
        tags = Set.new tt[id].tags.sample (rnd.rand 1..8), rnd rescue next
        Wool::Command::DeleteTags.new({id: id, tags: tags}).exec sweater
        tt[id].tags.subtract tags
      end
      tt.each do |id, t|
        (Wool::Command::Get.new({id: id}).exec sweater).should eq t
        (sweater.get_relations id).should eq(Set.new tt.values.select { |rt| ((c = rt.content).is_a? Wool::Relation) && ((c.from == id) || (c.to == id)) })
      end
      i += 1
    end
  end

  it "conversion", focus: true do
    batch = Wool::Convertible::Batch.from_yaml File.read config[:conversion][:src]
    commands = batch.convert
    commands.each { |c| c.exec sweater }
  end
end
