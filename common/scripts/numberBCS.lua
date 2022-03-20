-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Some values to cache to reduce processing
local isMisc = false;
local sNotePath = nil;
local widget = nil;
local sMiscFieldName = nil;

-- strip out formattedtext from a string (Courtesy of Celestrian - https://www.fantasygrounds.com/forums/showthread.php?44196-Formattedtext-for-tooltips)
function stripFormattedText(sText)
	local sTextOnly = sText;
	sTextOnly = sTextOnly:gsub("</p>","\n");
	sTextOnly = sTextOnly:gsub("<.?[ubiphUBIPH]>","");
	sTextOnly = sTextOnly:gsub("<.?table>","");
	sTextOnly = sTextOnly:gsub("<.?frame>","");
	sTextOnly = sTextOnly:gsub("<.?t.?>","");
	sTextOnly = sTextOnly:gsub("<.?list>","");
	sTextOnly = sTextOnly:gsub("<.?li>","");
	return sTextOnly;  
end


-- NOTE: We purposely do not define onInit() as it appears doing so overrides some other low-level template's onInit() 
--       and then the number field does not function properly.


function onFirstLayout()
	if super and super.onFirstLayout then
		super.onFirstLayout()
	end

	-- We aren't doing anything with read-only fields.
	if isReadOnly() then
		return false;
	end

	-- If it is a field with "misc" in its name, then continue processing.
	local name = self.getName();
	if name:find("misc",1,true) then
		
		-- Figure out where to store the misc note.  We can't just append it onto the existing DB path
		-- as it could be contained within a structure that something else is parsing and relying on the exact format.
		--
		-- So...  we will create a new XML section called "miscnotes" for the char (PC or NPC cohort) and then use 
		-- the existing path to the misc value to mimic its unique position in the list of "miscnotes".

		isMisc = true;
		local sPath = DB.getPath(self.getDatabaseNode()); 

		-- First check for cohorts, then regular PC if no cohort found
		local sCharSheetPath, sMiscPath  = sPath:match("^(charsheet%..+%.cohorts%.id%-%d+)%.(.-)$");
		if not sCharSheetPath then
        	sCharSheetPath, sMiscPath = sPath:match("^(charsheet.id%-%d+)%.(.-)$");
		end

		-- Only add the widget if this is a charsheet node.
		if sCharSheetPath then
			sMiscFieldName = sMiscPath;
			sNotePath = sCharSheetPath .. ".miscnotes." .. sMiscPath;

			local dbNode = DB.findNode(sNotePath .. ".text");
			local sNoteText = "";
			if dbNode then
				sNoteText = dbNode.getText();
			end

			if sNoteText and sNoteText ~= "" then
				widget = addBitmapWidget("combobox_button_active");
				setTooltipText(sNoteText);
			else
				widget = addBitmapWidget("combobox_button");
				setTooltipText("CTRL-click to add note.");
			end
			widget.setPosition("bottomright", 0, 0);
		end

		-- We want to get notified whenever the value of the note changes.
		DB.addHandler(DB.getPath(sNotePath), "onChildUpdate", sourceupdate);
	end
end

function onClose()
	DB.removeHandler(DB.getPath(sNotePath), "onChildUpdate", sourceupdate);
end

function sourceupdate()
	if self.onSourceUpdate() then
		self.onSourceUpdate();
	end
end

function onSourceUpdate()

	-- We got notifed the note changed, so fetch the text
	-- and update the note's status icon and tooltip.

	local dbNode = DB.findNode(sNotePath .. ".text");
	local sNoteText = "";

	if widget then
		widget.destroy();
		widget = nil;
	end

	if dbNode then
		sNoteText = dbNode.getText();
	end

	if sNoteText and sNoteText ~= "" then
		widget = addBitmapWidget("combobox_button_active");
		setTooltipText(sNoteText);
	else
		widget = addBitmapWidget("combobox_button");
		setTooltipText("CTRL-click to add note.");
	end
	widget.setPosition("bottomright", 0, 0);
end


function onClickDown(button, x, y)
	-- Always return nil so lower level controls continue to process the click.
	-- If this is not done, then you can never click to set the focus of the field
	-- for typing values.
    local returnCode = nil;

	if super and super.onClickDown then
		returnCode = super.onClickDown(button, x, y);
	end

	-- Bail if not a misc field
	if not isMisc then
		return returnCode;
	end
	
	if isReadOnly() then
		return returnCode;
	end
	
	if not Input.isControlPressed() then
		return returnCode;
	end
	
	if button and button == 1 then		
		local w = Interface.openWindow("misc_note", sNotePath);	
		w.title.setValue(sMiscFieldName);
		return nil;
	end

	return returnCode;
end