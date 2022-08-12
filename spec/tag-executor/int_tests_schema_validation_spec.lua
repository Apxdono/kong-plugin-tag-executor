local helpers = require "spec.helpers"
local say = require "say"
local pl_file = require "pl.file"

local PLUGIN_NAME = "tag-executor"

local kong_startup_options = function(config)
  return {
    database           = "off",
    nginx_conf         = "spec/fixtures/custom_nginx.template",
    plugins            = "bundled," .. PLUGIN_NAME,
    declarative_config = config
  }
end

local function error_in_log(state, arguments)
  local err_log_file = helpers.get_running_conf().nginx_err_logs
  local expected_string = arguments[1]
  local err_log = pl_file.read(err_log_file)

  return err_log:find(expected_string, 1, true) ~= nil
end

say:set("assertion.error_in_log.positive", "Expected nginx error log to contain:\n%s")
say:set("assertion.error_in_log.negative", "Expected nginx error log to not contain:\n%s")
assert:register("assertion", "error_in_log", error_in_log, "assertion.error_in_log.positive",
  "assertion.error_in_log.negative")

local function test_valid_config()
  local declarative_config = "/kong-plugin/spec/fixtures/test-declarative.yaml"

  helpers.start_kong(kong_startup_options(declarative_config))

  assert.not_error_in_log("error parsing declarative config file")
  helpers.stop_kong(nil, true)
end

local function test_config_with_no_named_step()
  local declarative_config = "/kong-plugin/spec/fixtures/no-named-step-config.yaml"

  helpers.start_kong(kong_startup_options(declarative_config))

  local expected_error = [[in 'plugins':
  - in entry 1 of 'plugins':
    in 'config':
      in 'tag_execute_steps':
        - in entry 1 of 'tag_execute_steps':
          in 'name': required field missing]]

  assert.error_in_log(expected_error)
  helpers.stop_kong(nil, true)
end

local function test_config_with_invalid_plugin_config()
  local declarative_config = "/kong-plugin/spec/fixtures/invalid-nested-plugin-config.yaml"

  helpers.start_kong(kong_startup_options(declarative_config))

  local expected_error = [[in 'plugins':
  - in entry 1 of 'plugins':
    in 'config':
      in 'tag_execute_steps':
        - in entry 1 of 'tag_execute_steps':
          in 'plugins':
            - in entry 1 of 'plugins':
              in 'adda': unknown field]]
  assert.error_in_log(expected_error)
  helpers.stop_kong(nil, true)
end

describe(PLUGIN_NAME .. ": (schema)", function()

  it("accepts valid config", test_valid_config)
  it("fails with no named steps config", test_config_with_no_named_step)
  it("fails with invalid nested plugin config", test_config_with_invalid_plugin_config)

end)
