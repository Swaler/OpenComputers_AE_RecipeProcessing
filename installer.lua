-- original installer can look in https://github.com/IgorTimofeev/MineOS/blob/master/Installer/Main.lua

local function getComponentAddress(name)
    return component.list(name)() or error("Required " .. name .. " component is missing")
end

local internetAddress = getComponentAddress("internet")

local repositoryURL = "https://github.com/Swaler/OpenComputers_AE_RecipeProcessing/blob/main/"
local installerURL = "Installer/"

local temporaryFilesystemProxy, selectedFilesystemProxy

local function filesystemHideExtension(path)
    return path:match("(.+)%..+") or path
end

local function rawRequest(url, chunkHandler)
    local internetHandle, reason = component.invoke(internetAddress, "request",
        repositoryURL .. url:gsub("([^%w%-%_%.%~])", function(char)
            return string.format("%%%02X", string.byte(char))
        end))

    if internetHandle then
        local chunk, reason
        while true do
            chunk, reason = internetHandle.read(math.huge)

            if chunk then
                chunkHandler(chunk)
            else
                if reason then
                    error("Internet request failed: " .. tostring(reason))
                end

                break
            end
        end

        internetHandle.close()
    else
        error("Connection failed: " .. url)
    end
end

local function request(url)
    local data = ""

    rawRequest(url, function(chunk)
        data = data .. chunk
    end)

    return data
end

local function download(url, path)
    selectedFilesystemProxy.makeDirectory(filesystemPath(path))

    local fileHandle, reason = selectedFilesystemProxy.open(path, "wb")
    if fileHandle then
        rawRequest(url, function(chunk)
            selectedFilesystemProxy.write(fileHandle, chunk)
        end)

        selectedFilesystemProxy.close(fileHandle)
    else
        error("File opening failed: " .. tostring(reason))
    end
end

local function deserialize(text)
    local result, reason = load("return " .. text, "=string")
    if result then
        return result()
    else
        error(reason)
    end
end

local files = deserialize(request(installerURL .. "Files.cfg"))
print(files.text)
