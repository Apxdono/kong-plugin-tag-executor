[![Build Status](https://github.com/Apxdono/kong-plugin-tag-executor/actions/workflows/test.yml/badge.svg)](https://github.com/Apxdono/kong-plugin-tag-executor/actions)
[![LuaRocks](https://img.shields.io/luarocks/v/Apxdono/kong-plugin-tag-executor?color=%2300aaff)](https://luarocks.org/modules/Apxdono/kong-plugin-tag-executor)

# Kong plugin tag-executor

This plugin is designed specifically for Kong `dbless` with `declarative config` mode of operation. *If you're running Kong with database
and have outside tools/pipelines that control Kong's configuration this plugin is of little use to you.*

Goal of this plugin is to reduce duplication of huge plugin configurations for cases when plugins must be configured on specific routes (especially when number of `services` and
`routes` increases in your project all the time).

For this particular reason plugin utilizes Route `tags` to determine if plugin `phases` should be invoked.
(It feels like this feature belongs inside Kong's core functionality like it's done today with `route`, `service`, `consumer` references, but for now this plugin will do the job).

## Installation

Install the plugin using `luarocks`

```sh
luarocks install kong-plugin-tag-executor
```

## Capabilities

- Plugin can use configuration of any other plugin installed in Kong instance [referenec docs](https://docs.konghq.com/gateway/latest/reference/configuration/#plugins).
- Plugin is designed to work with `declarative_config` only (Tested only against `dbless` Kong). *In theory can work in 'Kong with DB' environments*.
- Execution of nested plugins and their phases respects Kong's [plugin execution order](https://docs.konghq.com/gateway/latest/plugin-development/custom-logic/#plugins-execution-order).
- Plugin is executed before any other plugin (has pretty High Priority)
- Plugin is supposed to be global (targeting tags provides really fine grained control).
- Can be used on specific `routes`, `services`, `consumers` (which defeats the purpose).
## Limitations

- Providing nested plugin configuration for `tag-executor` itself (self-config) has no effect. `tag-executor` plugin is omitted from phase executions to avoid potential overflows due to recursive calls.
- Works only with `HTTP/HTTPS` requests (No `stream` support yet?).


## Example
Below is the example configuration one might use in `declarative_config`:

```yaml
- name: tag-executor
  config:
    tag_execute_steps:
      - name: service-tracing-step
        target_tag: tracing
        plugins:
          - name: correlation-id
            config:
              header_name: correlation-id
              generator: uuid
              echo_downstream: true
          - name: request-transformer
            config:
              add:
                headers:
                  - X-Traced-With:correlation
      - name: another-step
          # More and more configurations
```

Whenever Kong receives a request this plugin invokes each of `tag_execute_steps`.
In this example when route that has `tracing` tag is matched, `correlation-id`
and `request-transformer` plugins are invoked and request to upstream gets
modified by the plugins.

## Configuration

|Property|Description|
|----|----|
|`name`<br/>*required*<br/><br/>**Type:** string|The name of the plugin, in this case `tag-executor`.|
|`config.tag_execute_steps`<br/>*required*<br/><br/>**Type:** array of record elements|The steps to invoke on each phase of the plugin.|
|`config.tag_execute_steps.[?].name`<br/>*required*<br/><br/>**Type:** string|Unique name of this step.|
|`config.tag_execute_steps.[?].target_tag`<br/>*optional*<br/><br/>**Type:** string|Tag to match on `route`. If not specified applies steps to all routes.|
|`config.tag_execute_steps.[?].plugins`<br/>*required*<br/><br/>**Type:** array of plugin configurations|Configurations of plugins to execute ([Kong declarative configuration format](https://docs.konghq.com/gateway/latest/reference/db-less-and-declarative-config/#declarative-configuration-format)). Refer to particular plugin documentation for configuration reference.|

### Notes to self/TODO

1. Upload to Luarocks via GH Actions
2. Write docs for Kong plugin hub
3. More testing
