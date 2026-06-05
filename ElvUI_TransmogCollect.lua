local addonName = ...

local E, B

local function CollectTransmog()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[TransmogCollect]|r Cannot use in combat.")
        return
    end

    local success, err = pcall(function()
        if not C_AppearanceCollection or not C_AppearanceCollection.CollectItemAppearance then
            print("|cffff0000[TransmogCollect]|r Transmog API not available.")
            return
        end

        local c = C_AppearanceCollection
        local collected = 0
        local alreadyKnown = 0

        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemID = GetContainerItemID(bag, slot)
                if itemID then
                    local appearanceID = C_Appearance.GetItemAppearanceID(itemID)
                    if appearanceID then
                        if c.IsAppearanceCollected(appearanceID) then
                            alreadyKnown = alreadyKnown + 1
                        else
                            local guid = GetContainerItemGUID(bag, slot)
                            if guid then
                                c.CollectItemAppearance(guid)
                                collected = collected + 1
                            end
                        end
                    end
                end
            end
        end

        -- Задержка чтобы показать итог ПОСЛЕ системных сообщений о каждом предмете
        C_Timer.After(0.5, function()
            if collected > 0 then
                if alreadyKnown > 0 then
                    print(format("|cff00ff00[TransmogCollect]|r Collected |cff00ff00%d|r new and |cffFFA500%d|r already known appearance(s).",
                        collected, alreadyKnown))
                else
                    print(format("|cff00ff00[TransmogCollect]|r Collected |cff00ff00%d|r new appearance(s).",
                        collected))
                end
            else
                if alreadyKnown > 0 then
                    print(format("|cffffee00[TransmogCollect]|r No new appearances to collect. |cffFFA500%d|r already known.",
                        alreadyKnown))
                else
                    print(format("|cffffee00[TransmogCollect]|r No appearances to collect."))
                end
            end
        end)
    end)

    if not success then
        print("|cffff0000[TransmogCollect Error]|r " .. tostring(err))
    end
end

local function CreateTransmogButton(bagFrame)
    if not bagFrame or not bagFrame.holderFrame then return end
    if bagFrame.transmogButton then return end

    local anchorButton = bagFrame.deconstructButton or bagFrame.vendorGraysButton
    if not anchorButton then return end

    local button = CreateFrame("Button", nil, bagFrame.holderFrame)
    button:Size(16 + E.Border)
    button:SetTemplate()
    button:Point("RIGHT", anchorButton, "LEFT", -5, 0)
    button:SetNormalTexture("Interface\\ICONS\\INV_Misc_TabardPVP_01")
    button:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
    button:GetNormalTexture():SetInside()
    button:SetPushedTexture("Interface\\ICONS\\INV_Misc_TabardPVP_01")
    button:GetPushedTexture():SetTexCoord(unpack(E.TexCoords))
    button:GetPushedTexture():SetInside()
    button:StyleButton(nil, true)
    button.ttText = "Collect Transmog"
    button:SetScript("OnEnter", B.Tooltip_Show)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        CollectTransmog()
    end)

    bagFrame.transmogButton = button

    if bagFrame.editBox then
        bagFrame.editBox:ClearAllPoints()
        bagFrame.editBox:Point("BOTTOMLEFT", bagFrame.holderFrame, "TOPLEFT", (E.Border * 2) + 18, E.Border * 2 + 2)
        bagFrame.editBox:Point("RIGHT", button, "LEFT", -5, 0)
    end
end

local MAX_RETRIES = 10

local function TryCreateButton(retries)
    retries = retries or 0
    if not B or not B.BagFrame then return end
    if B.BagFrame.transmogButton then return end

    if E.db and E.db.bags and E.db.bags.deconstruct
        and not B.BagFrame.deconstructButton
        and retries < MAX_RETRIES then
        E:Delay(0.1, function() TryCreateButton(retries + 1) end)
        return
    end

    CreateTransmogButton(B.BagFrame)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not IsAddOnLoaded("ElvUI") then return end

        E = unpack(ElvUI)
        B = E:GetModule("Bags")

        hooksecurefunc(B, "Layout", function(_, isBank)
            if isBank then return end
            if B.BagFrame and not B.BagFrame.transmogButton then
                E:Delay(0.15, TryCreateButton)
            end
        end)

        if B.BagFrame and not B.BagFrame.transmogButton then
            E:Delay(0.5, TryCreateButton)
        end

        self:UnregisterEvent("ADDON_LOADED")
    end
end)
