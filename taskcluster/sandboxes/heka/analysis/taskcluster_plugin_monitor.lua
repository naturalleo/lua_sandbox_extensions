-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--[[
# Taskcluster process_message and plugin termination monitor


## Sample Configuration
```lua
filename = 'bq_output_monitor.lua'
message_matcher = "Type =~ '^hindsight%.plugin%.'"
preserve_data = false
process_message_inject_limit = 10

alert = {
  disabled = false,
  prefix = true,
  throttle = 90,
  modules = {
    email = {recipients = {"trink@mozilla.com"}},
  },
}

```
--]]
require "string"
local alert = require "heka.alert"

function process_message()
    local mt = read_message("Type")
    local plugin = read_message("Fields[name]")

    if mt == "hindsight.plugin.stats" then
        local failures = read_message("Fields[deltas]", 0, 3) -- process message failures
        if plugin:match("^output") and failures > 0 then
            alert.send(plugin, "process_message failure", "The failed load file has been temporarily saved off for manual inspection/correction")
        elseif plugin:match("^input") and failures > 30 then
            alert.send(plugin, "process_message failure", "Cannot read data")
        end
        -- input and analysis process message failure are in actionable at this point
    elseif mt == "hindsight.plugin.terminated" then
        alert.send(plugin, "terminated", read_message("Payload"), 0) -- no throttling
    end
    return 0
end


function timer_event()
end