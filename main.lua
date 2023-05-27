---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Thomas Ludwig.
--- DateTime: 30.04.2023 17:14
---

local config = require("config")
local sensors = config["sensors"]
local displays = config["displays"]
local clutchOut = config["clutchOut"]
local wirelessPort = config["wirelessPort"]
local wiredModem = peripheral.wrap("top")
local labels = config["labels"]
local gearOut = config["gearOut"]
local currentFloor = 0
local isMoving = false
local targetFloor = 0
local lastFloor = 0
local lastFloorLabel = ""
local watchdogTimer = 0
local watchdogIsMoving = false

term.write("Elevator OS 1.0 - Core")



--- Elevator Sensor Scans
function scanSensors ()
    local isSensorTriggered = false
    local touchInput = rs.getAnalogueInput("right")

    for index = 1, #(sensors) do
        local sensorTriggered = scanSensor(index)

        if sensorTriggered == true then
            isSensorTriggered = true
            currentFloor = index
        end
    end

    if isSensorTriggered == false then
        currentFloor = 0
        goFloor(#(sensors))
    else
        checkPosition()
    end

    if touchInput > 0 and touchInput ~= currentFloor then
        goFloor(touchInput)
    end
end

function checkInvertedSensor(sensor)
    local firstItem = sensor.getItemDetail(1)
    if not firstItem then
        return true
    end

    return false
end

function scanSensor(index)
    if(peripheral.isPresent(sensors[index]) == false) then
        print("sensor " .. index .. " is missing, skipping!")
        return false
    end

    local sensor = peripheral.wrap(sensors[index])
    local firstItem = sensor.getItemDetail(1)
    if not firstItem then
        ---print("sensor " .. index .. " is empty, skipping!")
        return false
    end

    --print("sensor "..index.." got triggered!")

    return true
end



--- monitor function
function updateMonitors()
    local floor = "F: "..targetFloor
    local label = labels[targetFloor]

    local floorColor = "87f"
    local floorBackground = "fff"

    if currentFloor > 0 then
        lastFloor = currentFloor
    end

    if isMoving == true then
        floor = "F: "..lastFloor..">"..targetFloor

        if lastFloor > 9 then
            floorColor = floorColor.."33"
            floorBackground = floorBackground.."ff"
        else
            floorColor = floorColor.."3"
            floorBackground = floorBackground.."f"
        end

        floorColor = floorColor.."7"
        floorBackground = floorBackground.."f"
    end

    lastFloorLabel = floor

    if label == nil then
        label = "N/A"
    else
        label = ""..label
    end

    if targetFloor > 9 then
        floorColor = floorColor.."99"
        floorBackground = floorBackground.."ff"
    else
        floorColor = floorColor.."9"
        floorBackground = floorBackground.."f"
    end

    for index = 1, #(displays) do
        local display = peripheral.wrap(displays[index])

        display.clear()
        display.setBackgroundColor(colors.black)
        display.setTextScale(1)

        display.setCursorPos(1,5)

        if isMoving then
            display.blit("is busy","fffffff","1111111")
        end

        if currentFloor ~= index and isMoving == false then
            display.blit("call me","fffffff","9999999")
        end

        if currentFloor == index and isMoving == false then
            display.blit("is here","fffffff","ddddddd")
        end

        local x,y = display.getSize()
        local x2,y2 = display.getCursorPos()

        display.setTextColor(colors.gray)
        display.setCursorPos(1, 2)

        if isMoving == false then
            display.write("")
            display.setCursorPos(1, 2)
        else
            display.write("> ")
            display.setCursorPos(3, 2)
        end

        display.setTextColor(colors.cyan)
        display.write(label)
        display.setTextColor(colors.blue)
        display.setCursorPos(1, 3)
        display.blit(floor, floorColor, floorBackground)
    end
end



--- clutch function
function toggleClutch()
    local clutchComputer = peripheral.wrap(clutchOut)

    if clutchComputer.isOn() then
        clutchComputer.shutdown()
    else
        clutchComputer.turnOn()
    end
end
function isClutchEngaged()
    local clutchComputer = peripheral.wrap(clutchOut)
    return clutchComputer.isOn()
end



--- direction functions
function toggleDirection()
    local directionComputer = peripheral.wrap(gearOut)

    if directionComputer.isOn() then
        directionComputer.shutdown()
    else
        directionComputer.turnOn()
    end
end

function isGearUp()
    local directionComputer = peripheral.wrap(gearOut)
    return directionComputer.isOn()
end



--- dev stuff
function debugPeripheralNames()
    local names = peripheral.getNames()

    for index = 1, #(names) do
        if string.find(names[index], "dropper") then
            print(names[index])
        end
    end
end



--- move functions
function goFloor(target)
    if isMoving then
        return
    end

    if target < 1 then
        return
    end

    if target > #(sensors) then
        return
    end

    if target > currentFloor then
        if isGearUp() == false then
            toggleDirection()
        end
    else
        if isGearUp() then
            toggleDirection()
        end
    end

    --print("move elevator from "..currentFloor.." to "..target)

    isMoving = true
    targetFloor = target
    toggleClutch()
end

function checkPosition()
    if currentFloor ~= targetFloor then
        return
    end

    if isMoving == false then
        return
    end

    if isClutchEngaged() == true then
        return
    end

    if targetFloor == 1 then
        toggleClutch()
        isMoving = false
        return
    end

    if targetFloor == #(sensors) then
        toggleClutch()
        isMoving = false
        return
    end

    toggleClutch()
    isMoving = false
end



--- watchdog code
function watchdog()
    watchdogTimer = watchdogTimer+1

    if watchdogIsMoving ~= isMoving then
        watchdogTimer = 0
        watchdogIsMoving = isMoving
        return
    end

    if watchdogTimer == 3600 then
        wiredModem.transmit(wirelessPort, wirelessPort, "reboot")
        os.reboot()
    end
end



--- init
if isClutchEngaged() == false then
    toggleClutch()
end

if isGearUp() == false then
    toggleDirection()
end

scanSensors()
updateMonitors()

goFloor(#(sensors))

while true do
    scanSensors()
    updateMonitors()
    watchdog()
end