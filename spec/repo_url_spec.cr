require "./spec_helper"

describe RepoUrl do
  it "should be creatable" do
    RepoUrl.new("git", "foo").nil?.should eq(false)
  end
end
