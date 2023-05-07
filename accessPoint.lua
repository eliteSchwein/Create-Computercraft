---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Thomas Ludwig.
--- DateTime: 30.04.2023 22:00
---

local config = require("config")
local wiredModem = peripheral.wrap("bottom")

term.write("Elevator OS 1.0 - Access Point")

function modemReceive(event, modemSide, senderChannel, replyChannel, message, senderDistance)
    if (tonumber(senderChannel) ~= config["wirelessPort"]) then
        return
    end

    wiredModem.transmit(config["wirelessPort"], config["wirelessPort"], message)
end

peripheral.call("right", "open", config["wirelessPort"])

wiredModem.open(config["wirelessPort"])

while true do
    local event, param1, param2, param3, param4, param5 = os.pullEvent()

    if(event == "modem_message") then
        modemReceive(event, param1, param2, param3, param4, param5)
    end
end