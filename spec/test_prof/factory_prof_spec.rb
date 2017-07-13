# frozen_string_literal: true

require "spec_helper"

# Init FactoryProf and patch FactoryGirl
TestProf::FactoryProf.init
TestProf::FactoryProf.configure do |config|
  # turn on stacks collection
  config.mode = :flamegraph
end

describe TestProf::FactoryProf, :transactional do
  before { described_class.start }
  after { described_class.stop }

  # Ensure meta-queries have been performed
  before(:all) { User.first }

  describe "#result" do
    subject(:result) { described_class.result }

    it "has no stacks when no data created" do
      FactoryGirl.build_stubbed(:user)
      User.first
      expect(result.stacks.size).to eq 0
    end

    it "contains simple stack" do
      FactoryGirl.create(:user)
      expect(result.stacks.size).to eq 1
      expect(result.total).to eq 1
      expect(result.stacks.first).to eq([:user])
    end

    it "contains many stacks" do
      FactoryGirl.create_pair(:user)
      FactoryGirl.create(:post)
      FactoryGirl.create(:user, :with_posts)

      expect(result.stacks.size).to eq 4
      expect(result.total).to eq 9
      expect(result.stacks).to contain_exactly(
        [:user],
        [:user],
        %i[post user],
        %i[user post user post user]
      )
      expect(result.stats).to eq(
        [
          { name: :user, total: 6, top_level: 3 },
          { name: :post, total: 3, top_level: 1 }
        ]
      )
    end
  end
end
