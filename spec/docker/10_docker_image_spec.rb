# encoding: UTF-8
require "docker_helper"

describe "Package" do
  [
    "bash",
    "curl",
    "jq",
    "libressl",
    "lighttpd",
    "lighttpd-mod_auth",
  ].each do |package|
    context package do
      it "is installed" do
        expect(package(package)).to be_installed
      end
    end
  end
end

describe "Docker entrypoint file" do
  context "/docker-entrypoint.sh" do
    it "has set permissions" do
      expect(file("/docker-entrypoint.sh")).to exist
      expect(file("/docker-entrypoint.sh")).to be_executable
    end
  end
  [
    "/docker-entrypoint.d/10-default-command.sh",
  ].each do |file|
    context file do
      it "exists" do
        expect(file(file)).to exist
        expect(file(file)).to be_readable
      end
    end
  end
end
