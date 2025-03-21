class PortHelper < Formula
  desc "🚀 端口转发管理工具 - 自动转发 + 自动关闭 + 菜单管理"
  homepage "https://github.com/extrafan/port-helper"
  url "https://github.com/extrafan/brew-port-helper/archive/refs/tags/v1.0.0.tar.gz"
  version "1.0.0"
  sha256 "89060cee609b76074e8520f1b880ea75f8648aa40fcbeea6dd17e640115325ca"

  def install
    bin.install "port-helper.sh" => "port-helper"
  end
end

