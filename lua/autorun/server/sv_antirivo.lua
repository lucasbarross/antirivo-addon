local playersConnected = {}
local PERSISTENT_UUID_KEY = "Antirivo.GetServerUUID"
local roundOver = true

util.AddNetworkString( "Antirivo.UserToken" )
util.AddNetworkString( "Antirivo.CheckRegistered" )
util.AddNetworkString( "Antirivo.Success" )

concommand.Add( "ar_move_dead", function(ply, cmd, args)
    if(args[1] == "1")
        hook.Add( "TTTBodyFound", "Antirivo.BodyFound", MoveUserDead )
    elseif (args[1] == "0")
        hook.Remove("TTTBodyFound", "Antirivo.BodyFound")
    end
end )

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

local SERVER_UUID = GetServerUUID()

local function MuteUser(ply)
    if ply:SteamID() == "STEAM_0:0:0" then return end
    
    if roundOver then return end
    
    local steamID = ply:SteamID()
    local token = playersConnected[steamID]
    if ply:IsConnected() then
        http.Post( "https://antirivo.herokuapp.com/mute/" .. steamID .. "/" .. SERVER_UUID .. "?token=" .. token, {},
        function( result )
        end,
        function( error )
        end
    )
end
end

local function ShowUserToken(ply, token)
    net.Start("Antirivo.UserToken")
    net.WriteString(token)
    net.WriteEntity(ply)
    net.Send(ply)
end

local function GenerateNewPlayerToken(ply)
    local steamID = ply:SteamID()
    http.Post( "https://antirivo.herokuapp.com/token/" .. steamID .. "/" .. SERVER_UUID, {},
    function( result )
        result = util.JSONToTable(result)
        if result.response.status == "Error" then
            ply:Kick("There's an error with the Antirivo-TTT addon.")
        elseif result.response.status == "Success" then
            ShowUserToken(ply, result.response.token)
        end
    end,
    function( error )
        ply:Kick("There's an error with the Antirivo-TTT addon.")
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
            playersConnected[steamID] = body.response.token
            net.Send(ply)
        end
    end,
    function( error )
        ply:Kick("There's an error with the Antirivo-TTT addon.")
    end
)
end

local function CheckToken( ply )
    if ply:SteamID() == "STEAM_0:0:0" then return end
    FetchToken(ply)
end

local function CheckRegistered(len, ply)
    local msg = net.ReadEntity()
    FetchToken(ply)
end

local function MoveUser(channel, ply)
    tokens = {}
    if ply == 'all' then
        for key, value in pairs(playersConnected) do
            tokens[#tokens+1] = value
        end
    else
        tokens[#tokens+1] = playersConnected[ply:SteamID()]
    end
    
    tokens = util.TableToJSON(tokens)
    
    local body = {}
    body['tokens'] = tokens
    
    http.Post( "https://antirivo.herokuapp.com/move/" .. SERVER_UUID .. "?channel=" .. channel, body,
    function( result )
    end,
    function( error )
    end
)
end

local function MoveUserDead(ply, deadply)
    if not roundOver then
        MoveUser('dead', deadply)
    end
end

local function RoundBegin()
    roundOver = false
    MoveUser('alive', 'all')
end

local function RoundOver()
    roundOver = true
    MoveUser('alive', 'all')
end

net.Receive("Antirivo.CheckRegistered", CheckRegistered)
hook.Add( "PlayerInitialSpawn", PERSISTENT_UUID_KEY, CheckToken )
hook.Add( "PostPlayerDeath", "Antirivo.PlayerDeath", MuteUser )
hook.Add( "TTTBodyFound", "Antirivo.BodyFound", MoveUserDead )
hook.Add( "TTTEndRound", "Antirivo.EndRound", RoundOver )
hook.Add( "TTTBeginRound", "Antirivo.BeginRound", RoundBegin )
hook.Add( "TTTPrepareRound", "Antirivo.PrepareRound", RoundBegin )