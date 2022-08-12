local helpers = require "spec.helpers"
local say     = require("say")

local PLUGIN_NAME = "tag-executor"

local function starts_with(state, arguments)
  local prefix_pattern = "^" .. arguments[1]
  local target_string = arguments[2]

  return target_string:find(prefix_pattern) ~= nil
end

say:set("assertion.starts_with.positive", "Expected prefix %s in string %s")
say:set("assertion.starts_with.negative", "Expected prefix %s to not be in %s")
assert:register("assertion", "starts_with", starts_with, "assertion.starts_with.positive",
  "assertion.starts_with.negative")

local function start_db_less()
  assert(helpers.start_kong({
    database           = "off",
    -- use the custom test template to create a local mock server
    nginx_conf         = "spec/fixtures/custom_nginx.template",
    -- make sure our plugin gets loaded
    plugins            = "bundled," .. PLUGIN_NAME,
    -- load declarative config from <repo>/spec/fixtures
    declarative_config = "/kong-plugin/spec/fixtures/test-declarative.yaml",
  }))
end

describe(PLUGIN_NAME .. ": (access) [#dbless]", function()
  local client

  lazy_setup(start_db_less)

  lazy_teardown(function()
    helpers.stop_kong(nil, true)
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then client:close() end
  end)

  local function test_users_external_api()
    local resp = client:get("/apiext/users/external", {})

    assert.response(resp).has.status(200)
    local correlation_id = assert.request(resp).has.header("correlation-id")
    -- Tracker would place ip first in correlation id value
    assert.not_starts_with("127.0.0.1", correlation_id)

    local request_type_value = assert.request(resp).has.header("x-request-type")
    assert.equal("external-request", request_type_value)

    local traced_value = assert.request(resp).has.header("x-traced-with")
    assert.equal("correlation", traced_value)

    assert.request(resp).has.header("x-no-tag-ran")
  end

  local function test_phones_external_api()
    local resp = client:get("/apiext/phones/external", {})

    assert.response(resp).has.status(200)
    local correlation_id = assert.request(resp).has.header("correlation-id")
    -- Tracker would place ip first in correlation id value
    assert.not_starts_with("127.0.0.1", correlation_id)

    local request_type_value = assert.request(resp).has.header("x-request-type")
    assert.equal("external-request", request_type_value)

    local traced_value = assert.request(resp).has.header("x-traced-with")
    assert.equal("correlation", traced_value)

    assert.request(resp).has.header("x-no-tag-ran")
  end

  local function test_users_internal_api()
    local resp = client:get("/apiint/users/internal", {})

    assert.response(resp).has.status(200)
    assert.request(resp).not_has.header("x-request-type")

    local correlation_id = assert.request(resp).has.header("correlation-id")
    -- Tracker would place ip first in correlation id value
    assert.starts_with("127.0.0.1", correlation_id)

    assert.request(resp).not_has.header("x-traced-with")

    assert.request(resp).has.header("x-no-tag-ran")
  end

  local function test_phones_internal_api()
    local resp = client:get("/apiint/phones/internal", {})

    assert.response(resp).has.status(200)
    local correlation_id = assert.request(resp).has.header("correlation-id")
    -- Tracker would place ip first in correlation id value
    assert.not_starts_with("127.0.0.1", correlation_id)

    assert.request(resp).not_has.header("x-request-type")

    local traced_value = assert.request(resp).has.header("x-traced-with")
    assert.equal("correlation", traced_value)

    assert.request(resp).has.header("x-no-tag-ran")
  end

  describe("users service external api request", function()
    it("receives transformed headers", test_users_external_api)
  end)

  describe("phones service external api request", function()
    it("receives transformed headers", test_phones_external_api)
  end)

  describe("users service internal api request", function()
    it("receives transformed headers", test_users_internal_api)
  end)

  describe("phones service internal api request", function()
    it("receives transformed headers", test_phones_internal_api)
  end)

end)
-- end
