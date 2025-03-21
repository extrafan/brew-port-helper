class PortHelper < Formula
  desc "🚀 端口转发管理工具 - 自动转发 + 自动关闭 + 菜单管理"
  homepage "https://github.com/extrafan/port-helper"
  url "https://github.com/extrafan/brew-port-helper/archive/refs/tags/v1.0.0.tar.gz"
  version "1.0.0"
  sha256 "db86609f3584c5441bb749d1b9deb3f7ee2132edfb4db73ce0aa2963b8abc939"

  def install
    bin.install "port-helper.sh" => "port-helper"
  end
end

