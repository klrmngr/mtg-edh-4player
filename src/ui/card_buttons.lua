--------------------- GLOBAL-SCRIPT BUTTONS ON ENCODED CARDS --------------------
-- The Encoder owns the button set on every card it has encoded: each rebuild
-- (dropping a keyword token, writing a notepad, the untap sweep clearing a stun
-- counter, making a token copy, ...) starts with clearButtons(), which silently
-- drops any button the Global script put on that card.
--
-- Rather than chase every rebuild site -- and lose the race against modules that
-- redraw on their own update rather than inline -- we register once with the
-- Encoder and it calls us back at the end of each rebuild, after its own buttons
-- (see APIregisterButtonProvider in objects/Encoder.02e062.lua). That callback is
-- synchronous, so the button is never actually missing for a frame.
--
-- To give a card feature buttons that survive the Encoder, add it to
-- globalCardButtons below. Handlers must be cheap and must no-op for cards they
-- don't care about: this runs on every rebuild of every encoded object.

globalCardButtonProviderId = "mtg4p_global"

-- called from onload. The Encoder module registers itself on Global a few frames
-- in, so wait for it rather than assuming it's up.
--
-- APIregisterButtonProvider is a local addition to our copy of the Encoder (see
-- the header of objects/Encoder.02e062.lua). Right-clicking the Encoder and
-- choosing "Update" would pull upstream's Encoder Core over it and take the API
-- with it, so say so out loud rather than letting card buttons quietly start
-- vanishing again.
function registerGlobalCardButtons()
	Wait.condition(function()
		local ok = pcall(function()
			Encoder.call("APIregisterButtonProvider", {
				id = globalCardButtonProviderId,
				funcOwner = Global,
				func = "globalCardButtons",
			})
		end)
		if not ok then
			broadcastToAll(
				"Encoder is missing APIregisterButtonProvider -- this table's card buttons "
					.. "(Mindmoil, Etali, Ping, Ral, ...) will disappear whenever a card's buttons are rebuilt. "
					.. "Was the Encoder updated from upstream?",
				{ 1, 0.6, 0.2 }
			)
		end
	end, function()
		return Encoder ~= nil
	end)
end

-- the Encoder has just rebuilt p.obj's buttons; put ours back on top. p.inHand is
-- true when the rebuild was for a card in someone's hand.
function globalCardButtons(p)
	local obj = p and p.obj
	if obj == nil then
		return
	end
	cardTriggersReassert(obj)
end
