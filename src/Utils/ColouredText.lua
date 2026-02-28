ColouredText = {}

function ColouredText.black(text)
    return "\27[30m" .. text .. "\27[0m"
end

function ColouredText.red(text)
    return "\27[31m" .. text .. "\27[0m"
end

function ColouredText.green(text)
    return "\27[32m" .. text .. "\27[0m"
end

function ColouredText.yellow(text)
    return "\27[33m" .. text .. "\27[0m"
end

function ColouredText.blue(text)
    return "\27[34m" .. text .. "\27[0m"
end

function ColouredText.magenta(text)
    return "\27[35m" .. text .. "\27[0m"
end

function ColouredText.cyan(text)
    return "\27[36m" .. text .. "\27[0m"
end

function ColouredText.white(text)
    return "\27[37m" .. text .. "\27[0m"
end

function ColouredText.default(text)
    return "\27[39m" .. text .. "\27[0m"
end

return ColouredText
