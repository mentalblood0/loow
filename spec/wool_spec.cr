require "spec"

require "../src/wool"

rnd = Random.new 0

describe Wool do
  sweater = Wool::Sweater.from_yaml File.read "spec/config.yml"

  it "adds" do
    c1 = rnd.hex 16
    c2 = rnd.hex 16

    id1 = sweater.add c1
    (sweater.get id1).should eq({tags: nil, content: c1})

    id2 = sweater.add c2
    (sweater.get id2).should eq({tags: nil, content: c2})

    rel = {from: id1, to: id2, type: Wool::Type::AnswerTo}
    idr1 = sweater.add rel
    (sweater.get idr1).should eq({tags: nil, content: rel})
  end
end
