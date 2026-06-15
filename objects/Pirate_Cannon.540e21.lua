fx = {Fire = 0,	Idle = 0, Move = 1}

settings = {
	barrelOffset  = {x=    0, y= 1.15, z= -1.8},
	muzzleOffset  = {x= -0.2, y= 5.2 , z=  0.8},
	muzzleOffset2 = {x=  0.2, y= 5.6 , z=  2.1},
	minSpin   = 60,
	maxSpin   = 120,
	errorColor = {1, 0.4, 0.4},
	infoColor = {0.8, 0.8, 1},
	useRecoil = false,
}

help = {
	lowPower        = "Power is too low. Check object description",
	nothingSelected = "You don't have anything selected",
	objtoolarge     = "%s is too large to be auto-loaded",
	unreadablePower = "Couldn't read Power from description. Example: [00CED1]Power: 25-32[ffffff]",
	buttonFireLabel = "Fire!",
	buttonLoadLabel = "Load",
	buttonFireLabel = "Fire!",
	buttonLockLabel = "Lock",
	buttonUnlock    = "Unlock",
	buttonLoad      = "Load selected objects into the cannon.\nIf nothing is selected, repeat the previous payload.",
	buttonLock      = "You must lock the cannon in place \nin order to load objects properly."
}

--Runtime
rotationAtLaunch     = {}
posAtLaunch          = {}
memorizedObjects     = {}
nrOfMemorizedObjects = {}
isFiring = false

function onload()
	CreateButtons()
	self.tooltip = false
end

function FireCannon(obj, color)

	if isFiring then return end

	local power, launchVelocity = CalcPowerAndLaunchVelocity(color)

	if power > 0 then
		isFiring = true
		self.AssetBundle.playTriggerEffect(fx.Fire)
		LaunchBarrelContents(launchVelocity)
		AfterFire()
	end

end

function AddObjects(obj,color)

	local barrelContents = GetBarrelContents()
	local selectedObjects = Player[color].getSelectedObjects()
	local firableObjects, nrOfFirable = GetFirableObjects(selectedObjects)

	if nrOfFirable > 0 then
		memorizedObjects[color] = firableObjects
		nrOfMemorizedObjects[color] = nrOfFirable
	else
		firableObjects = memorizedObjects[color] or {}
		nrOfFirable = nrOfMemorizedObjects[color] or 0
	end

	if nrOfFirable == 0 then
		firableObjects = memorizedObjects["no color"] or {}
		nrOfFirable = nrOfMemorizedObjects["no color"] or 0
	end

	if nrOfFirable == 0 then broadcastToColor(help.nothingSelected, color, settings.infoColor) return end

	local objectsToMove = {}
	for thisObjGUID,_ in pairs(firableObjects) do
		local thisObj = getObjectFromGUID(thisObjGUID)
		if thisObj and (not barrelContents[thisObjGUID]) then
			table.insert(objectsToMove, thisObj)
		end
	end

	if #objectsToMove > 0 then
		self.setLock(true)
		Shuffle(objectsToMove)
		MoveTableToBarrel({objs = objectsToMove})
	end
end

function LaunchBarrelContents(launchVelocity)
	local barrelContents, nrOfBarrelContents = GetBarrelContents()
	for thisObjGUID,_ in pairs(barrelContents) do
		local launchSpin = settings.minSpin + math.random() * (settings.maxSpin - settings.minSpin)
		LaunchObject(getObjectFromGUID(thisObjGUID), launchVelocity, launchSpin)
	end
end

function AfterFire()
	if settings.useRecoil then
		rotationAtLaunch = self.getRotation()
		posAtLaunch = self.getPosition()
		-- CreateTimer(self.GetGUID() .. "Unlock", "Unlock", 0.2)
		CreateTimer(self.GetGUID() .. "Recoil", "Recoil", 0.23, {power = power})
		CreateTimer(self.GetGUID() .. "Reset" , "Reset" , 2.8)
		CreateTimer(self.GetGUID() .. "Lock"  , "Lock"  , 3.5)
	else
		CreateTimer(self.GetGUID() .. "Reset" , "Reset" , 2.5)
	end
end


function CalcPowerAndLaunchVelocity(color)

 	-- Help avoid end of barrel by raising the angle slightly
 	local launchDirection = rotateVec3(self.getTransformForward(), self.getTransformRight(), 45)
	local desc = self.getDescription()
	local powerMin, powerMax = desc:match("Power:%s*([%d%.]+)%s*-?%s*([%d%.]*)")
	powerMin = tonumber(powerMin)  powerMax = tonumber(powerMax) or powerMin

	if (not powerMin) or (not powerMax) then
		broadcastToColor(help.unreadablePower, color, settings.errorColor)
		print(string.format("[ff6666]%s", help.unreadablePower) )
		return 0
	end

	local power = powerMin + math.random() * (powerMax - powerMin)
	if power <= 0 then broadcastToColor(help.lowPower, color, settings.errorColor) return 0 end

	local launchVelocity = {launchDirection.x * power, launchDirection.y * power, launchDirection.z * power}

	return power, launchVelocity

end

function CreateTimer(timerName, funcName, delay, params)

	local parameters = {}
	parameters.identifier     = timerName
	parameters.function_name  = funcName
	parameters.delay          = delay

	if params and type(params) == 'table' then
		parameters.parameters = params
	end

	Timer.create(parameters)

end

function Reset()
	if settings.useRecoil then
		self.setPositionSmooth(posAtLaunch, false, true)
		self.setRotationSmooth(rotationAtLaunch, false, true)
	end
	isFiring = false
end

function Lock()
	self.setLock(true)
	self.interactable = true
end

function Unlock()
	self.interactable = false -- prevent outlines during firing
	self.setLock(false)
end

function ToggleLock()
	self.setLock(not self.GetLock())
end

function Recoil(args)
	local fwdDirection = rotateVec3(self.getTransformForward(), self.getTransformRight(), -11)
	local power = args.power/2 + 3
	if power > 0 then
		local pushVelocity = {
			fwdDirection.x * power * -1,
			fwdDirection.y * power * -1,
			fwdDirection.z * power * -1
			}
		self.setVelocity(pushVelocity)
	end
end

function LaunchObject(thisObj, launchVelocity, launchSpin)
	if thisObj ~= self then

		local spin = {}
		spin.x = math.random() * launchSpin
		spin.y = math.random() * (launchSpin - spin.x)
		spin.z = (launchSpin - spin.x - spin.y)

		--randomly invert some of the axes
		spin.x = spin.x * (math.random(0,1)*2-1)
		spin.y = spin.y * (math.random(0,1)*2-1)
		spin.z = spin.z * (math.random(0,1)*2-1)

		--Use setVelocity so that mass can be ignored
		thisObj.setVelocity(launchVelocity)
		thisObj.setAngularVelocity(spin)


		-- pieHere, if who-goes-firest die is launched, set turn when it rests
		if thisObj.getName()=='goes first!' then
			thisObj.interactable=false
			Wait.frames(function()
				Wait.condition(function()
					thisObj.interactable=true
					local goesFirst=thisObj.getRotationValue()
					for _,ply in pairs(Player.getPlayers()) do
						if ply.steam_name==goesFirst then
							Turns.enable = true
							Turns.turn_color = ply.color
							break
						end
					end
				end, function() return thisObj.resting end)
			end,5)
		end

	end
end

function GetBarrelContents()

	local castSize    = 2 * self.getScale().x
 	local hitResults = Physics.cast(
		{
        origin       = self:positionToWorld( settings.barrelOffset ),
        direction    = rotateVec3( self.getTransformForward(), self.getTransformRight(), 45 ),
        type         = 2, -- sphere
        size         = {castSize,castSize,castSize},
        max_distance = 7.3 * self.getScale().x,
        debug        = false
    	}
	)

	local barrelContents = {}
	local nrOfObjects = 0
	for _,hit in ipairs(hitResults) do
		if hit.hit_object ~= self then
			nrOfObjects = nrOfObjects + 1
			barrelContents[hit.hit_object.getGUID()] = true
		end
	end

	return barrelContents, nrOfObjects

end

function GetFirableObjects(t)
	local validObjects = {}
	local nrOfFirable = 0

	for _,o in ipairs(t) do
		if (o.GetLock() == false) and IsSmallEnough(o) then
			validObjects[o.getGUID()] = true
			nrOfFirable = nrOfFirable + 1
		end
	end

	return validObjects, nrOfFirable
end

function IsSmallEnough(obj)
	local size = obj.getBoundsNormalized().size
	local barrelSize = self.getScale().x * 1.8

	local result = size.x < barrelSize and size.y < barrelSize and size.z < barrelSize
	if result == false then
		local n = obj.getName() if n == "" then n = obj.name end
		print(string.format(help.objtoolarge, n ))
	end

	return result
end

function MoveTableToBarrel(params)
	local objs = params.objs
	if objs and #objs > 0 then
		local thisObj = table.remove(objs, 1)
		if thisObj.GetLock() == false then
			local o1 = settings.muzzleOffset
			local o2 = settings.muzzleOffset2
			local rndPoint = math.random()
			local thisPosition = {
				o1.x + math.random()*(o2.x-o1.x),
				o1.y + rndPoint*(o2.y-o1.y),
				o1.z + rndPoint*(o2.z-o1.z)
				}
			thisObj.setPositionSmooth(self:positionToWorld( thisPosition ), false, true)
		end
		if #objs > 0 then
			CreateTimer(objs[1].GetGUID() .. "MoveTableToBarrel", "MoveTableToBarrel", 0.2, {objs = objs})
		end
	end
end

function CreateButtons()

	local b = {}
	b.function_owner = self
	b.color          = {0.05, 0.05, 0.05, 0.9}
	--b.color          = {0.75, 0.75, 0.75, 0.9}
	b.font_color     = {0.7, 0.7, 0.7, 1}

	b.label          = help.buttonFireLabel
	b.click_function = 'FireCannon'
	b.tooltip        = help.buttonFire
	b.width          = 280
	b.height         = 360
	b.position       = {0, 3.32, -2.55}
	b.rotation       = {25, 180, 0}
	self.createButton(b)

	b.width          = 500
	b.height         = 400
	b.position       = {1.26, 2.8, -1.8}
	b.rotation       = {13, -65, 55}
	self.createButton(b)

	b.width          = 500
	b.height         = 400
	b.position       = {-1.26, 2.8, -1.8}
	b.rotation       = {13, 65, -55}
	self.createButton(b)


	b.label          = help.buttonLoadLabel
	b.click_function = 'AddObjects'
	b.tooltip        = help.buttonLoad
	b.width          = 300
	b.height         = 350
	b.position       = {0, 4.68, 0.19}
	b.rotation       = {28, 180, 0}
	self.createButton(b)

	b.width          = 480
	b.height         = 400
	b.position       = {1.08, 4.2, 0.6}
	b.rotation       = {14, -61, 55}
	self.createButton(b)

	b.width          = 480
	b.height         = 400
	b.position       = {-1.08, 4.2, 0.6}
	b.rotation       = {14, 61, -55}
	self.createButton(b)

	-- b.label          = help.buttonLockLabel
	-- b.click_function = 'ToggleLock'
	-- b.tooltip        = help.buttonLock
	-- b.width          = 400
	-- b.height         = 400
	-- b.position       = {0, 0.22, -3.00}
	-- b.rotation       = {0, 180, 0}
	-- self.createButton(b)

end

function onPickedUp(player_color)
	self.AssetBundle.playLoopingEffect(fx.Move)
end

function onDropped(player_color)
	self.AssetBundle.playLoopingEffect(fx.Idle)
end

function onCollisionEnter(hit)
	if not isFiring then
		local p = self.positionToLocal(hit.contact_points[1])
		local obj = hit.collision_object
		local tag = obj.type
		-- local name = obj.getName() if name =='' then name = obj.name end
		-- print(string.format("%s, %.2f %.2f %.2f", name, p[1], p[2], p[3]))

		--Approximate location of the red vent hole
		if tag ~= 'Dice' and p[2] > 2.9 and p[3] < -1.7 then
			FireCannon(nil, "no color")
		end
	end
end

function Shuffle(t)
	local length = #t
	for i = length, 1, -1 do
		local thisIndex = math.random(length)
		t[i], t[thisIndex] = t[thisIndex], t[i]
	end
	return t
end

--  Functions to let us rotate a vector around an axis. -------------------
--  This lets us point the cannon shot

function dotProduct(a, b)
	return a[1]*b[1] + a[2]*b[2] + (a[3] or 0)*(b[3] or 0)
end

-- multiply vector v by matrix with rows r1, r2 and r3
function applyMatrixRowsToVec3(v, r1, r2, r3)
    return {dotProduct(v, r1), dotProduct(v, r2), dotProduct(v, r3)}
end

-- Create rotation vectors for angle (radians) about unit vector u
function rotationVectors(u, angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
	local d = 1-c
    local su = {s*u[1], s*u[2], s*u[3]}
    local du = {d*u[1], d*u[2], d*u[3]}
    local r1 = {du[1]*u[1] + c, du[1]*u[2] + su[3], du[1]*u[3] - su[2]}
    local r2 = {du[2]*u[1] - su[3], du[2]*u[2] + c, du[2]*u[3] + su[1]}
    local r3 = {du[3]*u[1] + su[2], du[2]*u[2] - su[1], du[3]*u[3] + c}
    return r1, r2, r3
end

--  Return vector v rotated angle degrees around vector u.
function rotateVec3(v, u, angle)
	local rads = angle * math.pi / 180
	local v2 = applyMatrixRowsToVec3(v, rotationVectors(u, rads))
	v2.x = v2[1]
	v2.y = v2[2]
	v2.z = v2[3]
    return v2
end

-- END Math functions ----------------------------------------------------------