local component = require("component")
local term = require("term")
local io = require("io")
local ser = require("serialization")
local fs = require("filesystem")
local shell = require("shell")
local modem = component.modem
local modemPort = 199

local program = "ctrl.lua"
local tableToFileName = "tableToFile.lua"
local settingFileName = "doorSettings.txt"
local configFileName = "extraConfig.txt"
local singleCode = {"https://raw.githubusercontent.com/cadergator10/opensecurity-scp-security-system/main/src/doorcontrols/singleDoor.lua","https://raw.githubusercontent.com/cadergator10/opensecurity-scp-security-system/main/test/experimentalCode/singleDoor.lua"}
local multiCode = {"https://raw.githubusercontent.com/cadergator10/opensecurity-scp-security-system/main/src/doorcontrols/multiDoor.lua","https://raw.githubusercontent.com/cadergator10/opensecurity-scp-security-system/main/test/experimentalCode/multiDoor.lua"}
local versionHolderCode = "https://raw.githubusercontent.com/cadergator10/opensecurity-scp-security-system/main/src/versionHolder.txt"

local settingData = {}
local randomNameArray = {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m"}
local commandArray = {"getInput","analyzer","clearTerm","terminate"}

local query = {["num"]=0}
local editorSettings = {}

local function saveTable(table, location)
    --saves a table to a file
    local tableFile = assert(io.open(location, "w"))
    tableFile:write(ser.serialize(table))
    tableFile:close()
end
local function loadTable(location)
    --returns a table stored in a file.
    local tableFile = assert(io.open(location))
    return ser.unserialize(tableFile:read("*all"))
end

local function sendMsg(...)
    for i=1,#arg,1 do
        argType = type(arg[i])
        if editorSettings.accelerate == true then
            if argType == "string" then
                modem.send(editorSettings.from,editorSettings.port,"print",arg[i])
            elseif argType == "int" then
                modem.send(editorSettings.from,editorSettings.port,commandArray[arg[i]])
                if arg[i] < 3 then
                    local e, _, _, _, _, text = event.pull("modem_message")
                    return text
                end
                if arg[i] == 4 then
                    print("terminated connection")
                end
            else
                modem.send(editorSettings.from,editorSettings.port,"print","potential error in code for sendMsg")
            end
        else
            if argType == "string" then
                print(arg[i])
            elseif argType == "int" then
                if arg[i] == 1 then
                    local text = term.read()
                    return text:sub(1,-2)
                elseif arg[i] == 2 then
                    return "nil"
                elseif arg[i] == 3 then
                    term.clear()
                elseif arg[i] == 4 then
                    print("Finished editing.")
                else
                    print("potential error in code for sendMsg")
                end
            end
        end
    end
    return true
end

local function runInstall()
    local tmpTable = {}
    local times = 1
    local text = ""
    if editorSettings.type == "multi" then
        os.execute("wget -f " .. multiCode[editorSettings.num]] .. " " .. program)
        if editorSettings.times ~= nil then
            tmpTable = editorSettings.data --TODO: Double check if this works later when finished
            times = editorSettings.times
        else
            text = sendMsg("Read the text carefully. Some of the inputs REQUIRE NUMBERS ONLY! Some require text.","The redSide is always 2, or back of the computer.","How many different doors are there?",1)
            times = tonumber(text)
        end
    else
        os.execute("wget -f " .. singleCode[editorSettings.num]] .. " " .. program)
    end
    os.execute("wget -f " .. tableToFileCode .. " " .. tableToFileName)

    local config = {}
    config.type = editorSettings.type
    config.num = editorSettings.num
    config.version = editorSettings.version
    text = sendMsg("Do you want to use the default cryptKey of {1,2,3,4,5}?","1 for yes, 2 for no",1)
    if tonumber(text) == 2 then
        config.cryptKey = {}
        sendMsg("there are 5 parameters, each requiring a number. Recommend doing 1 digit numbers cause I got no idea how this works lol")
        for i=1,5,1 do
            text = sendMsg("enter param " .. i,1)--TODO: Finish this!
            config.cryptKey[i] = tonumber(text)
        end
    else
        config.cryptKey = {1,2,3,4,5}
    end
    saveTable(config,configFileName)

    for i=1,times,1 do
        local loopArray = {}
        sendMsg(3)
        local j
        if editorSettings.type == "multi" then
            sendMsg("Door # " .. i .. " is being edited:")
            local keepLoop = true
            while keepLoop do
            j = randomNameArray[math.floor(math.random(1,26))]..randomNameArray[math.floor(math.random(1,26))]..randomNameArray[math.floor(math.random(1,26))]..randomNameArray[math.floor(math.random(1,26))]
                keepLoop = false
                for key,value in pairs(tmpTable) do
                    if key == j then
                        keepLoop = true
                    end
                end
            end
        end
        text = sendMsg("Magnetic card reader?",editorSettings.scanner and "Scan the magnetic card reader with your tablet" or "Enter the uuid of the device in TEXT",editorSettings.scanner and 2 or 1)
        loopArray["reader"] = text
        text = sendMsg(editorSettings.type == "multi" and "Door Type? 0= doorcontrol. 2=bundled. 3=rolldoor. NEVER USE 1! NUMBER ONLY" or "Door Type? 0= doorcontrol. 1= redstone 2=bundled. 3=rolldoor. NUMBER ONLY",1)
        loopArray["doorType"] = tonumber(text)
        if loopArray.doorType == 2 then
            text = sendMsg("What color. Use the Color API wiki provided in discord, and enter the NUMBER",1)
            loopArray["redColor"] = tonumber(text)
            if editorSettings.type == "multi" then
                sendMsg("No need to input anything for door address. The setting doesn't require it :)")
                loopArray["doorAddress"] = ""
            else
                text = sendMsg("What side? 0=bottom, 1=top, 2=back, 3=front, 4=right, 5=left. NUMBER ONLY",1)
                loopArray["redSide"] = tonumber(text)
            end
        elseif loopArray.doorType == 1 then
            loopArray["redColor"] = 0
            text = sendMsg("No need for redColor! The settings you inputted before don't require it :)","What side? 0=bottom, 1=top, 2=back, 3=front, 4=right, 5=left. NUMBER ONLY",1)
            loopArray["redSide"] = tonumber(text)
        else
            loopArray["redColor"] = 0
            if editorSettings.type == "single" then loopArray["redSide"] = 0 end
            sendMsg("no need to input anything for redColor. The setting doesn't require it :)",editorSettings.type == "single" and "no need to input anything for redSide. The setting doesn't require it :)" or nil)
            if editorSettings.type == "multi" then
                text = sendMsg("What is the address for the doorcontrol/rolldoor block?", editorSettings.scanner and "Scan the block with tablet" or "Enter uuid as text",editorSettings.scanner and 2 or 1)
                loopArray["doorAddress"] = text
            end
        end
        text = sendMsg("Should the door be toggleable, or not? 0 for autoclose and 1 for toggleable",1)
        loopArray["toggle"] = tonumber(text)
        if loopArray.toggle == 0 then
            text = sendMsg("How long should the door stay open in seconds? NUMBER ONLY",1)
            loopArray["delay"] = tonumber(text)
        else
            sendMsg("No need to change delay! Previous setting doesn't require it :)")
            loopArray["delay"] = 0
        end
        if editorSettings.num == 1 then
            text = sendMsg("What should be read? 0 = level; 1 = armory level; 2 = MTF;","3 = GOI; 4 = Security; 5 = Department; 6 = Intercom; 7 = Staff",1)
            loopArray["cardRead"] = tonumber(text)
            if loopArray.cardRead <= 1 or loopArray.cardRead == 5 then
                text = sendMsg("Access Level of what should be read? NUMBER ONLY",loopArray.cardRead ~= 5 and "level or armory level: enter the level that it should be." or "Department: 1=SD, 2=ScD, 3=MD, 4=E&T, 5=O5",1)
                loopArray["accessLevel"] = tonumber(text)
            else
                loopArray["accessLevel"] = 0
                sendMsg("No need to set access level. This mode doesn't require it :)")
            end
        else
            --TODO: Figure out how to set what the card reads with new system...
        end
        text = sendMsg("Is this door opened whenever all doors are asked to open? Not necessary if this is not Site 91","0 if no, 1 if yes. Default is yes",1)
        loopArray["forceOpen"] = tonumber(text)
        text = sendMsg("Is this door immune to lock door? Not necessary if this is not Site 91","0 if no, 1 if yes. Default is no",1)
        loopArray["bypassLock"] = tonumber(text)
        if editorSettings.type == "multi" then tmpTable[j] = loopArray else tmpTable = loopArray end
    end
    sendMsg("All done! You can remove internet card now. Run " .. program .. " now to start door!",4)

    return tmpTable
end

local function oldFiles()
    term.clear()
    local config = loadTable(configFileName)
    if config == nil then
        print("Error reading config file. Is this an up to date version?")
        print("It is recommended to wipe and reinstall at this point")
    end
    print("Old files detected. Please select an option:")
    print("1 = wipe all files (maybe)")
    print("2 = add more doors (very experimental)")
    print("3 = delete a door (very experimental)")
    print("4 = change a door (not implemented yet)")
    print("5 = update door")
    print("6 = change cryptKey")
    local text = term.read()
    if tonumber(text) == 1 then
        term.clear()
        print("Deleting all files...")
        local path = shell.getWorkingDirectory()
        fs.remove(path .. "/" .. program)
        fs.remove(path .. "/" .. tableToFileName)
        fs.remove(path .. "/" .. settingFileName)
        if config ~= nil then fs.remove(path .. "/" .. configFileName) end
        local fill = io.open(settingFileName)
        if fill~=nil then
            print("an error occured and some files may not have deleted.")
        else
            print("all done!")
        end
        fill:close()
    elseif tonumber(text) == 2 then
        if config.type == "single" then
            print("you cannot add more doors as this is a single door. If you want to swap to a multidoor,")
            print("wipe all files and reinstall as a multidoor.")
            os.exit()
        elseif config.type == "multi" then
            settingData = loadTable(settingFileName)
            print("how many doors would you like to add?")
            text = term.read()
            local num = tonumber(text)
            --local tempArray = runInstall(true,num,false) FIXME: Update runInstall to be smaller and more me-friendly
            for key, value in pairs(tempArray) do
                settingData[key] = value
            end
            saveTable(settingData,settingFileName)
            print("Added the doors. It is recommended you check if it worked, as this is experimental.")
        else
            print("error reading config file")
            os.exit()
        end
    elseif tonumber(text) == 3 then
        if config.type == "single" then
            print("You cannot remove a door as this is a single door. This only works on a multidoor.")
            print("If this is meant to be a multidoor, wipe all files and reinstall as a multidoor.")
            os.exit()
        elseif config.type == "multi" then
            settingData = loadTable(settingFileName)
            print("What is the key for the door?")
            text = term.read()
            settingData[text:sub(1,-2)] = nil
            saveTable(settingData,settingFileName)
            print("Removed the door. It is recommended you check if it worked, as this is experimental.")
        else
            print("error reading config file")
            os.exit()
        end
    elseif tonumber(text) == 4 then
        --TODO: Implement a more "efficient" program to change door
        if config.type == "single" then
            print("starting single door editing...")
        else
            print("Starting multi door editing...")
        end
    elseif tonumber(text) == 5 then
        print("Are you sure you want to do this? New updates sometimes require manual changing of config.")
        print("1 for continue, 2 for cancel")
        text = term.read()
        if tonumber(text) == 1 then
            if config.type == "single" then
                print("downloading...")
                if config.num == 1 then
                    os.execute("wget -f " .. singleCode[1] .. " " .. program)
                else
                    os.execute("wget -f " .. singleCode[2] .. " " .. program)
                end
            elseif config.type == "multi" then
                print("downloading...")
                if config.num == 1 then
                    os.execute("wget -f " .. multiCode[1] .. " " .. program)
                else
                    os.execute("wget -f " .. multiCode[2] .. " " .. program)
                end
            else

            end
        end
    elseif tonumber(text) == 6 then
        print("there are 5 parameters, each requiring a number. Recommend doing 1 digit numbers cause I got no idea how this works lol")
        for i=1,5,1 do
            print("enter param " .. i)
            text = term.read()
            config.cryptKey[i] = tonumber(text)
        end
        saveTable(config,configFileName)
        print("all done! is set to " .. ser.serialize(config.cryptKey))
    end
    config = nil
end

modem.close()
term.clear()
print("Sending query to server...")
modem.open(modemPort)
modem.broadcast(modemPort,"autoInstallerQuery")
local e,_,from,port,_,msg = event.pull(3,"modem_message")
if e == false then
    print("Failed. Is the server on?")
    os.exit()
end
print("Query received")
query = ser.unserialize(msg)
term.clear()
print("Checking files...")
local fill = io.open(program,"r")
if fill~=nil then
    fill:close()
    oldFile()
else

end