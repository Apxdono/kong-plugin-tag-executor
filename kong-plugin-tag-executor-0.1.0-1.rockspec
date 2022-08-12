local plugin_name = "tag-executor"
local package_name = "kong-plugin-" .. plugin_name
local package_version = "0.1.0"
local rockspec_revision = "1"

local github_account_name = "Apxdono"
local github_repo_name = "kong-plugin-tag-executor"
local git_checkout = package_version == "dev" and "master" or package_version


package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }
source = {
  url = "git+https://github.com/" .. github_account_name .. "/" .. github_repo_name .. ".git",
  tag = "v" .. package_version,
}


description = {
  summary = "Goal of this plugin is to reduce duplication of huge plugin configurations for cases when plugins must be configured on specific routes.",
  homepage = https://github.com/" .. github_account_name .. "/" .. github_repo_name .. ",
  license = "Apache 2.0",
}


dependencies = {
}


build = {
  type = "builtin",
  modules = {
    ["kong.plugins." .. plugin_name .. ".handler"] = "kong/plugins/" .. plugin_name .. "/handler.lua",
    ["kong.plugins." .. plugin_name .. ".schema"] = "kong/plugins/" .. plugin_name .. "/schema.lua",
  }
}
