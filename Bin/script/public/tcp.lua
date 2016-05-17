--[[
tcp����
--]]

local table = table
local string = string
local TCPBUFLENS_125 = 125
local TCPBUFLENS_126 = 126
local TCPBUFLENS_127 = 127

local tcp = {}

local function parseHead(objBinary)    
    if 0 >= objBinary:getSurpLens() then
        return nil, 0
    end
    
    local iPackLens = 0
    local iType = objBinary:getSint8()
    if iType <= TCPBUFLENS_125 then
        iPackLens = iType        
        return 1, iPackLens
    end
        
    if TCPBUFLENS_126 == iType then
        if 2 >  objBinary:getSurpLens() then
            return nil, iPackLens
        end
        
        iPackLens = objBinary:getUint16()        
        return 3, iPackLens
    end
        
    if TCPBUFLENS_127 == iType then
        if 4 > objBinary:getSurpLens() then
            return nil, iPackLens
        end
        
        iPackLens = objBinary:getUint32()
        
        return 5, iPackLens
    end
    
    return nil, 0
end

function tcp.parsePack(pRBinary, funcOnRead, ...)
    local iParsed = 0
    local iHeadLens = 0
    local iPackLens = 0
    local objBinary = pRBinary
    
    while true do
        iHeadLens, iPackLens = parseHead(objBinary)
        if not iHeadLens then
            break
        end
        
        if 0 == iPackLens then
            iParsed = objBinary:getReadedLens()
        else
            if iPackLens > objBinary:getSurpLens() then
                break
            end
            
            funcOnRead(objBinary:getByte(iPackLens), table.unpack({...}))
            iParsed = objBinary:getReadedLens()
        end
    end
    
    return iParsed
end

function tcp.creatPack(objBinary, strMsg)
    objBinary:reSetWrite()
    local iLens = string.len(strMsg)
    if iLens <= TCPBUFLENS_125 then
        objBinary:setSint8(iLens)
        objBinary:setByte(strMsg, iLens)
        
        return
    end
    
    if iLens > TCPBUFLENS_125 and iLens <= 65535 then
        objBinary:setSint8(TCPBUFLENS_126)
        objBinary:setUint16(iLens)
        objBinary:setByte(strMsg, iLens)
        
        return
    end
    
    objBinary:setSint8(TCPBUFLENS_127)
    objBinary:setUint32(iLens)
    objBinary:setByte(strMsg, iLens)
end

return tcp
