Antirivo_playersConnected = {}
local PERSISTENT_UUID_KEY = "Antirivo.GetServerUUID"

util.AddNetworkString( "Antirivo.UserToken" )
util.AddNetworkString( "Antirivo.CheckRegistered" )
util.AddNetworkString( "Antirivo.Success" )

local function Teste(ply, message)
    for k, ply in pairs( player.GetAll() ) do
        ply:ChatPrint( message or "hello world" )
    end
end

local function GenerateUUID()
    local bytes = {}
    for i = 1, 16 do bytes[i] = math.random(0, 0xFF) end
    bytes[7] = bit.bor(0x40, bit.band(bytes[7], 0x0F))
    bytes[9] = bit.bor(0x80, bit.band(bytes[7], 0x3F))
    return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", unpack(bytes))
end

local function GetServerUUID()
    local uuid = cookie.GetString(PERSISTENT_UUID_KEY)
    if not uuid then
        uuid = GenerateUUID()
        cookie.Set(PERSISTENT_UUID_KEY, uuid)
    end
    return uuid
end

local function ShowUserToken(ply, token)
    net.Start("Antirivo.UserToken")
    net.WriteString(token)
    net.WriteEntity(ply)
    net.Send(ply)
end

local function GenerateNewPlayerToken(ply)
    local serverUUID = GetServerUUID()
    local steamID = ply:SteamID()
    http.Post( "https://antirivo.herokuapp.com/token/" .. steamID .. "/" .. serverUUID, {},
        function( result )
            result = util.JSONToTable(result)
            if result.response.status == "Error" then
                ply:Kick("There's an error with the Antirivo-TTT addon.")
            elseif result.response.status == "Success" then
                -- playersConnected[ply:SteamID()] = result.response.token
                ShowUserToken(ply, result.response.token)
            end
        end,
        function( error )
            -- We failed. =(
        end
    )
end

local function FetchToken(ply)
    local steamID = ply:SteamID()
    local serverUUID = GetServerUUID()
    http.Fetch( "https://antirivo.herokuapp.com/token/" .. steamID .. "/" .. serverUUID,
        function( body, len, headers, code )
            body = util.JSONToTable(body)
            if body.response.status == "Error" then
                GenerateNewPlayerToken(ply)
            elseif body.response.status == "Success" and body.response.active == false then
                ShowUserToken(ply, body.response.token)
            else
                net.Start("Antirivo.Success")
                net.Send(ply)
            end
        end,
        function( error )
            -- We failed. =(
        end
    )
end

local function CheckToken( ply )
    if steamID == "STEAM_0:0:0" then return end
    FetchToken(ply)
end

local function CheckRegistered()
    local ply = net.ReadEntity()
    FetchToken(ply)
end

net.Receive("Antirivo.CheckRegistered", CheckRegistered)
hook.Add( "PlayerInitialSpawn", PERSISTENT_UUID_KEY, CheckToken )
hook.Add( "PostPlayerDeath", "antirivo_test", teste )