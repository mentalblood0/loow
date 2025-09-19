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

  it "generative" do
    tt = {} of Wool::Id => Wool::Thesis
    i = 0
    until i == 100
      case rnd.rand 0..3
      when 0
        c = rnd.hex 17
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = {content:   c,
                  relations: {from: Set(Wool::Id).new,
                              to: Set(Wool::Id).new},
                  tags: Set(String).new}
      when 1
        from = (tt.sample rnd rescue next)[0]
        to = (tt.sample rnd)[0]
        c = {from: from,
             to:   to,
             type: Wool::Type.values.sample rnd}
        id = Wool::Command::Add.new({c: c}).exec sweater
        tt[id] = {content:   c,
                  relations: {from: Set(Wool::Id).new,
                              to: Set(Wool::Id).new},
                  tags: Set(String).new}
        tt[from][:relations][:from] << id
        tt[to][:relations][:to] << id
      when 2
        id = (tt.sample rnd rescue next)[0]
        tags = Array.new (rnd.rand 1..8) { rnd.hex 1 }
        Wool::Command::AddTags.new({id: id, tags: tags}).exec sweater
        tt[id][:tags].concat tags
      when 3
        id = (tt.sample rnd rescue next)[0]
        tags = tt[id][:tags].sample (rnd.rand 1..8), rnd rescue next
        Wool::Command::DeleteTags.new({id: id, tags: tags}).exec sweater
        tt[id][:tags].subtract tags
      end
      sweater.ids.sort.should eq tt.keys.sort
      tt.each do |id, t|
        (Wool::Command::Get.new({id: id}).exec sweater).should eq t
      end
      i += 1
    end
  end

  it "conversion", focus: true do
    batch = Wool::Convertible::Batch.from_yaml File.read config[:conversion][:src]
    commands = batch.convert
    commands.each { |c| c.exec sweater }
    puts commands.to_yaml
  end
end
