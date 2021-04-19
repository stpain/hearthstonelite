--shop-games-legiondeluxe-card

local addonName, hsl = ...

local L = hsl.locales

local randomSeed = time()

local showHelptips = false;
local helptips = {}

local toastFrames = {};
local playerMixin = nil;

--- prints a message with addon name in []
local function printInfoMessage(msg)
    print("[|cff0070DDHearthstone Lite|r] "..msg)
end

--- adjusts the font size of a fontObject while keeping fontName and fontFlags intact
local function fontSizeHack(obj, size)
    -- font size hack
    local fontName, _, fontFlags = obj:GetFont()
    obj:SetFont(fontName, size, fontFlags)
end

--- hides all frames in the parent \<Frames\> element and then shows the frame given
---@param frame frame to be shown
local function navigateTo(frame)
    for k, frame in ipairs(HearthstoneLite.frames) do
        frame:Hide()
    end
    HearthstoneLite[frame]:Show()

    for k, frame in ipairs(helptips) do
        frame:SetShown(showHelptips)
    end
end

local function lootOpened()

    -- +++++ sample card table ++++++
    -- {
    --     art = 522189,                       -- the artwork of the card that appears in the upper section inset
    --     name = "Gut Ripper",                -- name on card
    --     health = 4,                         -- card health
    --     attack = 5,                          -- card attack
    --     ability = {
    --         power = 2,
    --         key = "attacksingle",
    --         callback = abilities.attacksingle,
    --     },
    --     battlecry = true,                  -- effect when entering battle
    --     deathrattle = false,                -- effect when dies
    --     cost = 3,                           -- mana gem cost to play
    --     backgroundPath = "neutral",         -- hero/set card belongs to -> this also determines the card background art
    --     background = 1,                     -- this is the background of the card, from topleft 1>14 as viewed on template.tga
    --     atlas = "NEUTRAL",                  -- this determines the texcoords used only weapon or neutral require different
    -- }

    local sourceGUIDs = {}

    for i = 1, GetNumLootItems() do
		local sources = {GetLootSourceInfo(i)}
		local _, name = GetLootSlotInfo(i)
		for j = 1, #sources, 2 do
			sourceGUIDs[sources[j]] = false;
		end
	end

    local frameCount = 1
    for GUID, _ in pairs(sourceGUIDs) do
        local creatureName = C_PlayerInfo.GetClass({guid = GUID})

        -- use these to determine the rarity of the card
        local rnd1 = math.floor(random()*10)
        local rnd2 = math.floor(random()*10)
        local rnd3 = math.floor(random()*10)
        local rnd4 = math.floor(random()*10)
        local rnd5 = math.floor(random()*10)

        -- generate some card values
        local _attack = math.ceil(math.floor(random()*10) * 0.7)
        local _health = math.ceil(math.floor(random()*10) * 0.7)
        local _ability, _abilityPower = nil, nil;
        local _hasAbility = (random(10) < 4) and true or false;
        if _hasAbility then
            _ability = hsl.db.abilities[random(#hsl.db.abilities)]
            _abilityPower = math.ceil(math.floor(random()*10) * 0.7)
        else
            _ability = { info = "", func = nil }
            _abilityPower = 0
        end

        -- does card have battleCry or deathRattle
        local _hasBCDR = (_attack < _health) and true or false;
        local _battlecry = false
        local _deathrattle = false
        if _hasBCDR then
            local bcdr = random(10)
            if bcdr < 6 then
                _battlecry = true;
            else
                _deathrattle = true;
            end
        end

        -- generate the cost
        local _cost = math.floor((_attack + _health) / 2)
        if _ability and _hasBCDR then
            _cost = _cost + math.floor((_abilityPower + 3) / 2)
        end
        -- cap cost at 9
        if _cost > 9 then
            _cost = 9
        end

        local showLoot = false;
        local loot = {
            art = 522189,
            name = creatureName,
            health = _health,
            attack = _attack,
            ability = {
                power = _abilityPower or 0,
                info = _ability.info or "",
                callback = _ability.func or nil,
            },
            battlecry = _battlecry,
            deathrattle = _deathrattle,
            cost = _cost,
            backgroundPath = "neutral",
            background = 1,
            atlas = "NEUTRAL",
        };


        if rnd2 > rnd1 then
            if rnd3 > rnd2 then
                if rnd4 > rnd3 then
                    if rnd5 > rnd4 then
                        --lego
                        showLoot = true;
                    else
                        --epic
                        showLoot = true;
                    end
                else
                    --rare
                    showLoot = true;
                end
            else
                --common
                showLoot = true;
            end
        end

        if not toastFrames[frameCount] then
            toastFrames[frameCount] = CreateFrame("FRAME", "HearthstoneLiteToastFrame"..frameCount, UIParent, "HslLootToast")
            toastFrames[frameCount]:SetPoint("CENTER", 0, -100)
            toastFrames[frameCount]:Hide()
        end

        if showLoot == true then
            toastFrames[frameCount]:Show();
            --print(loot.name, loot.attack, loot.health, loot.cost)
            print(string.format("Found card %s with %s attack and %s health and %s cost", loot.name, loot.attack, loot.health, loot.cost))
        end

        C_Timer.After(3, function()
            toastFrames[frameCount]:Hide()
        end)
    end
end


---deck view popout listview update function
---@param deck table the deck to view
local function deckViewerListview_Update(deck)
    if not deck then
        return
    end
    if not HSL then
        return
    end
    if not HSL.decks then
        return
    end

    table.sort(deck, function(a, b)
        return a.name < b.name;
    end)

    DeckBuilderMixin.deck = deck;

    local buttons = HybridScrollFrame_GetButtons(HearthstoneLite.deckBuilder.deckViewer.listview);
    local offset = HybridScrollFrame_GetOffset(HearthstoneLite.deckBuilder.deckViewer.listview);

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
        button:Hide()
    end

    local items = deck;

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
        local itemIndex = buttonIndex + offset

        if itemIndex <= #items then
            local item = items[itemIndex]
            button:SetCard(item)
            button:Show()

            button.card = item; --set the button.card to the hsl.db.card

            button.callback = deckViewerListview_Update;
        else
            button.card = nil;
            button:Hide()
        end
    end

    HybridScrollFrame_Update(HearthstoneLite.deckBuilder.deckViewer.listview, #deck * 36, HearthstoneLite.deckBuilder.deckViewer.listview:GetHeight())
end


---menu panel listview update function
---@param classID number the classID to be used when creating a new deck or loading decks
local function deckViewerDeckListview_Update(classID)
    if not HSL then
        return
    end
    if not HSL.decks then
        return
    end

    local buttons = HybridScrollFrame_GetButtons(HearthstoneLite.deckBuilder.menuPanel.listview);
    local offset = HybridScrollFrame_GetOffset(HearthstoneLite.deckBuilder.menuPanel.listview);

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex]
        button:Hide()
    end

    if HSL.decks[classID] then

        local items = HSL.decks[classID];

        for buttonIndex = 1, #buttons do
            local button = buttons[buttonIndex]
            local itemIndex = buttonIndex + offset

            if itemIndex <= #items then
                local item = items[itemIndex]
                button:SetText(item.name)
                button:SetClassID(classID)
                button:SetDeckID(item.id)
                button:Show()

                button.deleteDeck = deckViewerDeckListview_Update; -- dirty hack, when the delete button is pressed we call this function via Getparent()

                button.updateDeckViewer = deckViewerListview_Update
            else
                button:Hide()
            end
        end

        HybridScrollFrame_Update(HearthstoneLite.deckBuilder.menuPanel.listview, #HSL.decks[classID] * 40, HearthstoneLite.deckBuilder.menuPanel.listview:GetHeight())

    else
        for buttonIndex = 1, #buttons do
            local button = buttons[buttonIndex]
            button:Hide()
        end
    end
end




---this function is used to update the menu panel listview when a new class/hero is selected
---@param button table
local function classButton_Clicked(button)
    if button then
        for i = 1, GetNumClasses() do
            local className, classFile, classID = GetClassInfo(i)
            if button.className == classFile then
                --HearthstoneLite.deckBuilder.menuPanel.listviewHeader:SetText(className, 20);
                HearthstoneLite.deckBuilder.menuPanel.listviewHeader.newDeck.classID = classID;
                HearthstoneLite.deckBuilder.menuPanel.listviewHeader.newDeck.className = className;
                --HearthstoneLite.deckBuilder.menuPanel.listviewHeader.newDeck.classIcon = button.Background:GetAtlas();

                local class = classFile:sub(1,1):upper()..classFile:sub(2):lower()
                if class == "Deathknight" then
                    class = "DeathKnight";
                end

                HearthstoneLite.deckBuilder:HideCards()

                HearthstoneLite.deckBuilder.classFile = classFile;
                HearthstoneLite.deckBuilder.classID = classID;

                HearthstoneLite.deckBuilder.menuPanel.listviewHeader:SetIcon_Atlas(string.format("GarrMission_ClassIcon-%s", class))

                deckViewerDeckListview_Update(classID)
            end
        end
    end
end



HearthstoneLiteMixin = {}

function HearthstoneLiteMixin:OnLoad()

end

function HearthstoneLiteMixin:OnShow()

    -- set helptip text and add to helptips table
    self.menuHelptip.Text:SetText(L["MenuHelptip"])
    table.insert(helptips, self.menuHelptip)
end

HearthstoneButtonMixin = {}

function HearthstoneButtonMixin:OnMouseDown()
    navigateTo("home")
    self:AdjustPointsOffset(-1, -1)
end

function HearthstoneButtonMixin:OnMouseUp()
    self:AdjustPointsOffset(1, 1)
end

function HearthstoneButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
    GameTooltip:AddLine(L["Menu"])
    GameTooltip:Show()
end

function HearthstoneButtonMixin:OnLeave()
    GameTooltip:Hide()
end


ToggleHelptipMixin = {}

function ToggleHelptipMixin:OnMouseDown()
    showHelptips = not showHelptips;
    for k, frame in ipairs(helptips) do
        frame:SetShown(showHelptips)
    end
end




HomeMixin = {}

function HomeMixin:OnShow()

    fontSizeHack(self.deckBuilder.Text, 22)
    self.deckBuilder.Text:SetPoint("TOP", 0, -10)
    self.deckBuilder:SetText(L["DeckBuilder"])

    fontSizeHack(self.settings.Text, 22)
    self.settings.Text:SetPoint("TOP", 0, -10)
    self.settings:SetText(L["Settings"])


    -- introstinger ?
    --PlaySoundFile(1068313)

end

function HomeMixin:MenuButton_OnClick(frame)
    navigateTo(frame)
end



SettingsMixin = {}

function SettingsMixin:OnShow()
    self.resetSavedVar.Text:SetText('Reset saved var')
    self.resetSavedVar.Text:SetPoint("TOP", 0, -10)
end

function SettingsMixin:ResetGlobalSettings()
    StaticPopup_Show('ResetGlobalSettings', nil, nil, {callback = deckViewerDeckListview_Update})
end




DeckBuilderMixin = {}
DeckBuilderMixin.ClassID = nil;
DeckBuilderMixin.ClassFile = nil;

function DeckBuilderMixin:OnLoad()

    -- font size hack
    local fontName, _, fontFlags = self.menuPanel.selectClass:GetFont()
    self.menuPanel.selectClass:SetFont(fontName, 26, fontFlags)
    self.menuPanel.selectClass:SetText(L["SelectHero"])

    for i = 1, GetNumClasses() do
        local className, classFile, classID = GetClassInfo(i)
        if self.menuPanel[classFile:lower()] then
            self.menuPanel[classFile:lower()]:SetBackground_Atlas(string.format("classicon-%s", classFile:lower()))
            self.menuPanel[classFile:lower()].func = function()
                classButton_Clicked(self.menuPanel[classFile:lower()])
            end
        end
    end

    self.menuPanel.listviewHeader:SetSize(240, 40)
    self.menuPanel.listviewHeader:SetText(L["SelectDeck"], 20)

    HybridScrollFrame_CreateButtons(self.menuPanel.listview, "HslDeckListviewItem", -10, 0, "TOP", "TOP", 0, -1, "TOP", "BOTTOM")
    HybridScrollFrame_SetDoNotHideScrollBar(self.menuPanel.listview, true)



    self.cardViewer.showClass:Resize(40,40)
    self.cardViewer.showClass.func = function()
        if self.classFile then
            self:LoadCards(hsl.db.cards[self.classFile:lower()]);
        end
    end
    self.cardViewer.showNeutral:Resize(40,40)
    self.cardViewer.showNeutral:SetBackground_Atlas("GarrMission_ClassIcon-Warrior-Protection")
    self.cardViewer.showNeutral.func = function()
        self:LoadCards(hsl.db.cards.generic);
    end

    self.cardViewer.page = 1;

    -- flip the next page arrow 180
    self.cardViewer.nextPage.Background:SetRotation(3.14)
    self.cardViewer.nextPage.Highlight:SetRotation(3.14)

    fontSizeHack(self.cardViewer.pageNumber, 32)


    HybridScrollFrame_CreateButtons(self.deckViewer.listview, "HslCardListviewItem", -5, 0, "TOP", "TOP", 0, -1, "TOP", "BOTTOM")
    HybridScrollFrame_SetDoNotHideScrollBar(self.deckViewer.listview, true)

end

function DeckBuilderMixin:OnShow()

    -- deck open
    PlaySound(1068314)

    self.selectHeroHelptip.Text:SetText(L["SelectHeroHelptip"])
    self.selectHeroHelptip:Show()
    table.insert(helptips, self.selectHeroHelptip)

    self.cardViewer.deckEditingHelptip.Text:SetText(L["DeckEditingHelptip"])
    self.cardViewer.deckEditingHelptip:Show()
    table.insert(helptips, self.cardViewer.deckEditingHelptip)

    self.deckViewer.deckEditingHelptip_Popout.Text:SetText(L["DeckEditingHelptipPopout"])
    self.deckViewer.deckEditingHelptip_Popout:Show()
    table.insert(helptips, self.deckViewer.deckEditingHelptip_Popout)

    self.cardViewer.cardToggleHelptip.Text:SetText(L["ClassToggleHelptip"])
    self.cardViewer.cardToggleHelptip:SetSize(200, 40)
    self.cardViewer.cardToggleHelptip:Show()
    table.insert(helptips, self.cardViewer.cardToggleHelptip)

    deckViewerDeckListview_Update(nil)

    HearthstoneLite.deckBuilder:HideCards()

    self.deckViewer:Hide()

end

function DeckBuilderMixin:GetClassInfo()
    if self.classFile and self.classID then
        return { classFile = self.classFile, classID = self.classID }
    end
end

function DeckBuilderMixin:NextPage()
    if not self.deck then
        return;
    end

    if self.cardViewer.page == math.ceil(#self.deck / 8) then
        return;
    end
    self.cardViewer.page = self.cardViewer.page + 1;
    self.cardViewer.pageNumber:SetText(self.cardViewer.page..' / '..math.ceil(#self.deck / 8));

    local cardIndex = 1;

    for i = ((8 * self.cardViewer.page) - 7), (8 * self.cardViewer.page) do
        if self.deck[i] then
            self.cardViewer["card"..cardIndex]:LoadCard(self.deck[i])
        else
            self.cardViewer["card"..cardIndex]:ClearCard()
        end
        cardIndex = cardIndex + 1;
    end
end

function DeckBuilderMixin:PrevPage()
    if not self.deck then
        return;
    end
    if self.cardViewer.page == 1 then
        return
    end
    self.cardViewer.page = self.cardViewer.page - 1;
    self.cardViewer.pageNumber:SetText(self.cardViewer.page..' / '..math.ceil(#self.deck / 8));

    local cardIndex = 1;
    for i = ((8 * self.cardViewer.page) - 7), (8 * self.cardViewer.page) do
        if self.deck[i] then
            self.cardViewer["card"..cardIndex]:LoadCard(self.deck[i])
        else
            self.cardViewer["card"..cardIndex]:ClearCard()
        end
        cardIndex = cardIndex + 1;
    end
end

function DeckBuilderMixin:HideCards()
    for i = 1, 8 do
        if self.cardViewer["card"..i] then
            self.cardViewer["card"..i]:Hide()
        end
    end
end

function DeckBuilderMixin:LoadCards(deck)
    if not hsl.db.cards then
        return
    end
    if not deck then
        deck = hsl.db.cards.generic
    end
    if deck then
        self.deck = deck
        self.cardViewer.page = 1;
        self.cardViewer.pageNumber:SetText(self.cardViewer.page..' / '..math.ceil(#self.deck / 8));

        for i = 1, 8 do
            self.cardViewer["card"..i]:Hide()
        end

        for i = 1, 8 do
            if self.deck[i] then
                self.cardViewer["card"..i]:LoadCard(self.deck[i])
            end
        end
    end

    --deckViewerListview_Update(deck)
end

function DeckBuilderMixin:AddCard(card)
    if not HSL then
        return;
    end
    if not HSL.decks[self.classID] then
        return;
    end
    if HSL.decks and card then
        for _, deck in ipairs(HSL.decks[self.classID]) do
            if deck.id == self.deckID then
                -- card is from the hsl.db.cards table
                -- update the saved var table and pass back into the hybrid scroll update func
                table.insert(deck.cards, card)
                deckViewerListview_Update(deck.cards)
                --printInfoMessage(string.format("added %s to deck %s", card.name, deck.name))
                return;
            end
        end
    end
end

function DeckBuilderMixin:RemoveCard(card)
    if not HSL then
        return;
    end
    local cardIndex = nil;
    if HSL.decks and card then
        for _, deck in ipairs(HSL.decks[self.classID]) do
            if deck.id == self.deckID then
                for k, v in ipairs(deck.cards) do
                    -- since we are in the correct deck we can use the card name as uniqueness
                    -- if the card count is greater than 1 then we simple remove the card with
                    -- highest key this means only 1 card is removed
                    if v.name == card.name then
                        cardIndex = k;
                    end
                end
                if cardIndex then
                    -- update the saved var table and pass back into the hybrid scroll update func
                    table.remove(deck.cards, cardIndex)
                    deckViewerListview_Update(deck.cards)
                    return;
                end
            end
        end
    end
end


-- TODO:
-- this is using an old system to hold the class ID
-- update this to just use the DeckBuilderMixin
HslNewDeckMixin = {}

function HslNewDeckMixin:OnMouseDown()
    if self.classID > 0 then
        StaticPopup_Show("HslNewDeck", self.className, nil, {ClassID = self.classID, Icon = self.classIcon, callback = deckViewerDeckListview_Update})
    end
end







--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--
-- event frame
--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--
local e = CreateFrame("FRAME")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("LOOT_OPENED")
e:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...):lower() == "hearthstonelite" then
        print(L["HearthstoneLite"].." loaded!")
    end
    if event == "LOOT_OPENED" then
        lootOpened()
    end
end)