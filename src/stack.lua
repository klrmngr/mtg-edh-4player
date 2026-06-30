-- Stack tracker
-- Draws two long white lines running the length of the table (along x), parallel
-- to each other, one toward each long side. The central lane they frame is where
-- spells on the stack go. Each line spans a little over two playmats so it runs
-- the full length of a side.

stackHalfX = 42.0 -- half-length of each line; runs the entire length of the table
stackLineZ = 2.5 -- distance of each line from the table centre (sits between the playmats)
stackLineY = 0.965 -- just above the table surface (0.961) so the trackers sitting on it occlude the line
stackLineColor = { 1, 1, 1 } -- white

function drawStackLines()
	Global.setVectorLines({
		{
			points = {
				{ -stackHalfX, stackLineY, -stackLineZ },
				{ stackHalfX, stackLineY, -stackLineZ },
			},
			color = stackLineColor,
			thickness = 0.1,
			rotation = { 0, 0, 0 },
		},
		{
			points = {
				{ -stackHalfX, stackLineY, stackLineZ },
				{ stackHalfX, stackLineY, stackLineZ },
			},
			color = stackLineColor,
			thickness = 0.1,
			rotation = { 0, 0, 0 },
		},
	})
end
