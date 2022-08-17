local kong = kong
local plugin_name = "tag-executor"
local kong_types = require "kong.db.schema.typedefs"
local insert = table.insert

local optional_tag_typedef = kong_types.tag {
  required = false
}

local name_typedef = kong_types.name {
  required = true
}

local function get_schema(plug_name)
  return kong.db.plugins.schema.subschemas[plug_name]
end

local function validate_nested_plugin_config(plugin_record)
  local plugin_schema = get_schema(plugin_record.name)

  if not plugin_schema then
    return nil,
        string.format("plugin '%s' not enabled; add it to the 'plugins' configuration property", plugin_record.name)
  end

  local config_field = plugin_schema.fields["config"]
  if not config_field then
    kong.log.warn("Plugin " .. plugin_record.name .. " has no 'config' field. Skipping.")
    return true, nil
  end

  return plugin_schema:validate_field(config_field, plugin_record.config or nil)
end

local function init_empty_plugin_fields(plugin_config)

  for _, step in pairs(plugin_config.tag_execute_steps) do
    local initilized_configs = {}

    for _, plugin_record in pairs(step.plugins) do
      local plug_name = plugin_record.name
      local plugin_schema = get_schema(plug_name)

      local cnf = plugin_schema:process_auto_fields(plugin_record, "select", false)
      cnf["name"] = plug_name
      local transformed_config = plugin_schema:transform(cnf, plugin_record, nil)
      insert(initilized_configs, transformed_config)
    end
    -- @todo Figure out if inplace modification is a no no
    step.plugins = initilized_configs
  end

  return plugin_config
end

local nest_plugins_typedef = {
  type = "array",
  elements = {
    type = "record",
    custom_validator = validate_nested_plugin_config,
    fields = {
      { name = kong_types.name },
      {
        config = {
          type = "map",
          keys = kong_types.name,
          values = {
            type = "foreign",
          },
        }
      }
    }
  },
}

local step_item_typedef = {
  type = "record",
  fields = {
    { name = name_typedef },
    { target_tag = optional_tag_typedef },
    { plugins = nest_plugins_typedef },
  }
}

local steps_typedef = {
  type = "array",
  elements = step_item_typedef
}

local schema = {
  name = plugin_name,
  fields = {
    { config = {
      type = "record",
      fields = {
        { tag_execute_steps = steps_typedef },
      }
    }
    }
  },
  transformations = {
    {
      input = { "config" },
      on_write = init_empty_plugin_fields,
    }
  }
}

return schema
