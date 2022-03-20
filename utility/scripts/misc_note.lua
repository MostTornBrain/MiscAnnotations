-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


function onClose()
	-- If the "text" is empty, delete the node.
	if text.getValue() == "<p />" then
		DB.deleteNode(getDatabaseNode());
	end
end

