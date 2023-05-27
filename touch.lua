---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Thomas Ludwig.
--- DateTime: 30.04.2023 22:00
---

local config = require("config")
local displays = config["displays"]
local name = config["name"]
local wiredModem = peripheral.wrap("top")
local wirelessModem = peripheral.wrap("right")
local remotePort = config["wirelessPort"]+1

term.write("Elevator OS 1.0 - Touch")

function touchMonitor(event, side, xPos, yPos)
    for index = 1, #(displays) do
        local id = displays[index]

        if side == id then
            rs.setAnalogueOutput("left", index)
            os.sleep(1)
            rs.setOutput("left", false)
        end
    end
end

function modemReceive(event, modemSide, senderChannel, replyChannel, message, senderDistance)
    if (tonumber(senderChannel) ~= config["wirelessPort"]) then
        return
    end

    if message == 'reboot' then
        wirelessModem.transmit(remotePort, remotePort, "reboot")
        os.reboot()
    end

    rs.setAnalogueOutput("left", tonumber(message))
    os.sleep(1)
    rs.setOutput("left", false)
end

wirelessModem.open(config["wirelessPort"])
wiredModem.open(config["wirelessPort"])

while true do
    local event, param1, param2, param3, param4, param5 = os.pullEvent()

    if(event == "monitor_touch") then
        touchMonitor(event, param1, param2, param3)
    end

    if(event == "modem_message") then
        modemReceive(event, param1, param2, param3, param4, param5)
    end
end