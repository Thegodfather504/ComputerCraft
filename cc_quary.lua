
if not turtle then
    printError("Requires a Turtle")
    return
end

local size 
local length 
local width 
local depthHeight

local depth = 0
local unloaded = 0
local collected = 0

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local goTo -- Filled in further down
local refuel -- Filled in further down



local function paramCheck();
    if type(size) ~= "number" or size < 1 then
        print("Excavate diameter must be positive")
        print("type of size: " .. type(size) .. "value of size: " .. size)
        return false
    end
    if type(length) ~= "number" or length < 1 then
        print("Excavate length must be positive")
        return false
    end
    if type(width) ~= "number" or width < 1 then
        print("Excavate width must be positive")
        return false
    end
    if type(depthHeight) ~= "number" or depthHeight < 1 then
        print("Excavate depth must be positive")
        return false
    end
    return true
end

local function unload(_bKeepOneFuelStack)
    print("Unloading items...")
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            local bDrop = true
            if _bKeepOneFuelStack and turtle.refuel(0) then
                bDrop = false
                _bKeepOneFuelStack = false
            end
            if bDrop then
                turtle.drop()
                unloaded = unloaded + nCount
            end
        end
    end
    collected = 0
    turtle.select(1)
end

local function returnSupplies()
    local x, y, z, xd, zd = xPos, depth, zPos, xDir, zDir
    print("Returning to surface...")
    goTo(0, 0, 0, 0, -1)

    local fuelNeeded = 2 * (x + y + z) + 1
    if not refuel(fuelNeeded) then
        unload(true)
        print("Waiting for fuel")
        while not refuel(fuelNeeded) do
            os.pullEvent("turtle_inventory")
        end
    else
        unload(true)
    end

    print("Resuming mining...")
    goTo(x, y, z, xd, zd)
end

local function collect()
    local bFull = true
    local nTotalItems = 0
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount == 0 then
            bFull = false
        end
        nTotalItems = nTotalItems + nCount
    end

    if nTotalItems > collected then
        collected = nTotalItems
        if math.fmod(collected + unloaded, 50) == 0 then
            print("Mined " .. collected + unloaded .. " items.")
        end
    end

    if bFull then
        print("No empty slots left.")
        return false
    end
    return true
end

function refuel(amount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end

    local needed = amount or xPos + zPos + depth + 2
    if turtle.getFuelLevel() < needed then
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
                        turtle.refuel(1)
                    end
                    if turtle.getFuelLevel() >= needed then
                        turtle.select(1)
                        return true
                    end
                end
            end
        end
        turtle.select(1)
        return false
    end

    return true
end

local function tryForwards()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.forward() do
        if turtle.detect() then
            if turtle.dig() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attack() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end

    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

local function tryDown()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.down() do
        if turtle.detectDown() then
            if turtle.digDown() then
                if not collect() then
                    returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackDown() then
            if not collect() then
                returnSupplies()
            end
        else
            sleep(0.5)
        end
    end

    depth = depth + 1
    if math.fmod(depth, 10) == 0 then
        print("Descended " .. depth .. " metres.")
    end

    alternate = not alternate

    return true
end

local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

function goTo(x, y, z, xd, zd)
    while depth > y do
        if turtle.up() then
            depth = depth - 1
        elseif turtle.digUp() or turtle.attackUp() then
            collect()
        else
            sleep(0.5)
        end
    end

    if xPos > x then
        while xDir ~= -1 do
            turnLeft()
        end
        while xPos > x do
            if turtle.forward() then
                xPos = xPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif xPos < x then
        while xDir ~= 1 do
            turnLeft()
        end
        while xPos < x do
            if turtle.forward() then
                xPos = xPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end

    if zPos > z then
        while zDir ~= -1 do
            turnLeft()
        end
        while zPos > z do
            if turtle.forward() then
                zPos = zPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif zPos < z then
        while zDir ~= 1 do
            turnLeft()
        end
        while zPos < z do
            if turtle.forward() then
                zPos = zPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end

    while depth < y do
        if turtle.down() then
            depth = depth + 1
        elseif turtle.digDown() or turtle.attackDown() then
            collect()
        else
            sleep(0.5)
        end
    end

    while zDir ~= zd or xDir ~= xd do
        turnLeft()
    end
end

if not refuel() then
    print("Out of Fuel")
    return
end


local tArgs = { ... }
local programName = arg[0] or fs.getName(shell.getRunningProgram())
if #tArgs == 1 then
    size = tonumber(tArgs[1])
    length = size
    width = size
    depthHeight = size
elseif #tArgs == 3 then
    length = tonumber(tArgs[1])
    size = length
    width = tonumber(tArgs[2])
    depthHeight = tonumber(tArgs[3])
else
    print("Usage: " .. programName .. " <diameter>")
    print("or")
    print("Usage: " .. programName .. " <length> <width> <depth>")
    return
end

if not paramCheck(nil) then
    print("Parameters are not valid")
    print("Usage: " .. programName .. " <diameter> ")
    print("or")
    print("Usage: " .. programName .. " <length> <width> <depth>")
    return
end
print("Excavating...")

local reseal = false
turtle.select(1)
if turtle.digDown() then
    reseal = true
end

local alternate = false -- if the width is negative, set to true
local turnAround = false -- when the turtle reaches the end of the width, set to true 
local done = false
while not done do
    for n = 1, width do
        for _ = 1, length - 1 do
            if not tryForwards() then
                done = true
                break
            end
        end
        if done then
            break
        end
        if n < width then
            if alternate then
                turnLeft()
                if not tryForwards() then
                    done = true
                    break
                end
                turnLeft()
            else
                turnRight()
                if not tryForwards() then
                    done = true
                    break
                end
                turnRight()
            end
            alternate = not alternate
        else
            turnAround = true;
        end
    end
    if done then
        break
    end

    -- flag to 180

    if turnAround then
        if alternate then
            turnLeft()
            turnLeft()
        else
            turnRight()
            turnRight()
        end
        turnAround = false
    end

    if depth == depthHeight - 1 or not tryDown()  then
        done = true
        break
    end
end
print("Returning to surface...")
goTo(0, 0, 0, 0, -1)
unload(false)