surface.CreateFont("Antirivo's Arial", {
    font = "Arial",
    size = 40,
    weight = 500,
    antialias = true,
    shadow = false
} )

local function Success()
    chat.AddText( Color( 100, 100, 255 ), "Welcome, ", LocalPlayer())
end

local function checkRegistered(ply, frame)
    net.Start("Antirivo.CheckRegistered")
    net.WriteEntity(ply)
    net.SendToServer()
    frame:Close()
end

local function DrawGUI()
    local frame = vgui.Create("DFrame")
    -- frame:SetSize( ScrW() * 0.25, ScrH() * 0.25 )
    frame:SetSize( 480, 270 )
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)
    function frame:Paint(w,h)
        draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 600))
        draw.SimpleText("Antirivo's TTT authentication", "Default", 6, 2, color_white, 0, 0)
    end
    frame:SetDraggable( false )
    frame:Center()
    
    local token = net.ReadString()
    local player = net.ReadEntity()

    local txt_label_imperative = vgui.Create("DLabel", frame)
    txt_label_imperative:SetPos(77, 50)
    txt_label_imperative:SetText("Copy the code below and paste it on Discord with !ar prefix (!ar ".. token .. ").\nThen, click 'Ok'")
    txt_label_imperative:SizeToContents()
    txt_label_imperative:SetAutoStretchVertical(true)
    
    local txt_label_token = vgui.Create("DTextEntry", frame)
    txt_label_token:SetText(token)
    txt_label_token.OnChange = function(keycode) txt_label_token:SetText(token) end
    txt_label_token:SetTextColor(Color(0,255,0))
    txt_label_token:SetDrawBorder(false)
    txt_label_token:SetDrawBackground(false)
    txt_label_token:SetFont("Antirivo's Arial")
    txt_label_token:SetSize(154, 40)
    txt_label_token:Center()

    local button_ok = vgui.Create("DButton", frame)
    button_ok:SetText("Ok")
    button_ok:SetPos(208, 210)
    button_ok:SetSize(71, 25)
    button_ok.DoClick = function () checkRegistered(player, frame) end
end

net.Receive("Antirivo.UserToken", DrawGUI)
net.Receive("Antirivo.Success", Success)


-- */
-- 	// w = 400
-- 	// h = 30
-- 	// x = ScrW() - ScrW() * 0.5 - 200 
-- 	// y = 150
-- 	// ScrW() = 1900 !!! Your Screen width
-- 	// ScrH() = 1080 !!! Your Screen height
-- 	// x = 1900 - 1900 * 0.5 - 200 = 750
-- 	// 60 / 1900 ~= 0.0315
-- 	// 50 / 1080 = 0.0462

-- 	// Now you have dynamic X and Y coords ..
-- 	--surface.SetDrawColor(0,0,0,255)
-- 	--surface.DrawRect( 0.395 * ScrW(), ScrH() * 0.125, 400, 30 )
-- 	--surface.SetDrawColor(0,255,0,255)
-- 	--surface.DrawOutlinedRect(  0.395 * ScrW(), ScrH() * 0.125, 400, 30 )
-- 	// You want dynamic W/H values too ?
-- 	/*
-- 	 w = 400 / 1900 ~= 0.211
-- 	 h = 30 / 1080 = 0.025
-- 	 x = ScrW() - 0.5 * ScrW() - ScrW() * 0.1055  << == 0.211 * 0.5
-- 	 y = 0.125
-- 	*/