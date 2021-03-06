--[[
 _____                         _     _   _____                 _
|  ___|                       | |   | | |  __ \               (_)
| |__ _ __ ___   ___ _ __ __ _| | __| | | |  \/ __ _ _ __ ___  _ _ __   __ _
|  __| '_ ` _ \ / _ \ '__/ _` | |/ _` | | | __ / _` | '_ ` _ \| | '_ \ / _` |
| |__| | | | | |  __/ | | (_| | | (_| | | |_\ \ (_| | | | | | | | | | | (_| |
\____/_| |_| |_|\___|_|  \__,_|_|\__,_|  \____/\__,_|_| |_| |_|_|_| |_|\__, |
																		__/ |
																	   |___/
______ _____ _      ___________ _       _____   __
| ___ \  _  | |    |  ___| ___ \ |     / _ \ \ / /                           
| |_/ / | | | |    | |__ | |_/ / |    / /_\ \ V /
|    /| | | | |    |  __||  __/| |    |  _  |\ /          Created by
| |\ \\ \_/ / |____| |___| |   | |____| | | || |            Skully
\_| \_|\___/\_____/\____/\_|   \_____/\_| |_/\_/

Copyright of the Emerald Gaming Development Team, do not distribute - All rights reserved. ]]

emGUI = exports.emGUI
buttonFont_14 = emGUI:dxCreateNewFont(":emGUI/fonts/buttonFont.ttf", 11)

-- Disable vehicle engines when player enters.
addEventHandler("onClientPlayerVehicleEnter", root, function(theVehicle, seat)
	if (seat == 0) then
		setVehicleEngineState(theVehicle, false)
	end
end)

-- Window toggling.
function toggleWindowsClient(theVehicle, state)
	setVehicleWindowOpen(theVehicle, 2, state)
	setVehicleWindowOpen(theVehicle, 3, state)
	setVehicleWindowOpen(theVehicle, 4, state)
	setVehicleWindowOpen(theVehicle, 5, state)
end
addEvent("vehicle:toggleWindowsClient", true)
addEventHandler("vehicle:toggleWindowsClient", root, toggleWindowsClient)


function playerCarLockToggleFx(state)
	local sound = playSound(state and "sounds/lock/car_inside_lock.mp3" or "sounds/lock/car_inside_unlock.mp3")
end
addEvent("vehicle:playerCarLockToggleFx", true)
addEventHandler("vehicle:playerCarLockToggleFx", root, playerCarLockToggleFx)

function playerCarLockToggleFxOutside(p)
	local sound = playSound3D("sounds/lock/car_lock.mp3", p[1], p[2], p[3])
	if (sound) then
		setSoundMaxDistance(sound, 50)
		setSoundVolume(sound, 0.7)
		setElementInterior(sound, p[4])
		setElementDimension(sound, p[5])
	end
end
addEvent("vehicle:playerCarLockToggleFxOutside", true)
addEventHandler("vehicle:playerCarLockToggleFxOutside", root, playerCarLockToggleFxOutside)

function startEngineSound(theVehicle, isTail)
	local vehType = getElementData(theVehicle, "vehicle:type")
	local ignitionType = false
	if (vehType) then ignitionType = g_vehicleTypes[vehType]["ignition"] end
	if not (ignitionType) then triggerServerEvent("vehicle:startEngineCall", localPlayer, localPlayer, theVehicle) return end

	local ignitionSound = exports["sound-manager"]:playSoundEffect(localPlayer, ":vehicle-system/sounds/engine/" .. ignitionType .. ".wav", 0.5)
	local soungLength = math.max(getSoundLength(ignitionSound) * 800, 100)
	setTimer(function()
		if not (isTail) then triggerServerEvent("vehicle:startEngineCall", localPlayer, localPlayer, theVehicle) end
	end, soungLength, 1)

	if (isTail) then
		local playerVehicle = getPedOccupiedVehicle(localPlayer)
		if (playerVehicle == theVehicle) then
			setTimer(function()
				local sound = playSound("sounds/engine/" .. ignitionType .. "_tail.wav")
			end, soungLength, 1)
		else
			local x, y, z = getElementPosition(theVehicle)
			local dim, int = getElementDimension(theVehicle), getElementInterior(theVehicle)
			local sound = playSound3D("sounds/engine/exterior_stall.wav", x, y, z)
			if (sound) then
				setSoundVolume(sound, 3)
				setElementDimension(sound, dim)
				setElementInterior(sound, int)
			end
		end
	end
end
addEvent("vehicle:startEngineSound", true)
addEventHandler("vehicle:startEngineSound", root, startEngineSound)

function getElementSpeed(theElement)
	if not isElement(theElement) then return false end
	local x, y, z = getElementVelocity(theElement)
	return (x ^ 2 + y ^ 2 + z ^ 2) ^ 0.5 * 1.61 * 100
end

-- Vehicle mileage.
setTimer(function()
	local theVehicle = getPedOccupiedVehicle(localPlayer)
	if (theVehicle) and (getVehicleType(theVehicle) ~= "Bike") then
		local vs = getElementSpeed(theVehicle)
		local om = getElementData(theVehicle, "vehicle:mileage") or 0
		setElementData(theVehicle, "vehicle:mileage", om + vs)
	end
end, 2000, 0)

-- Vehicle door adjusting.
function showDoorAdjusterGUI(theVehicle)
	-- If vehicle is locked, prevent being able to adjust doors.
	if isVehicleLocked(theVehicle) then
		outputChatBox("You can't adjust the vehicle doors when it is locked.", 255, 0, 0)
		return false
	end

	local seatID = false -- If this exists, the user is in a specific seat and can only adjust that door.

	if (getVehicleOccupant(theVehicle, 0) == localPlayer) then seatID = 0
		elseif (getVehicleOccupant(theVehicle, 1) == localPlayer) then seatID = 1
		elseif (getVehicleOccupant(theVehicle, 2) == localPlayer) then seatID = 2
		elseif (getVehicleOccupant(theVehicle, 3) == localPlayer) then seatID = 3
	end

	local doorNames = {
		[0] = "Driver Door",
		[1] = "Passenger Door",
		[2] = "Rear Left Door",
		[3] = "Rear Right Door",
	}

	local labels = {}
	local scrollbars = {}


	if seatID then
		if (seatID == 0) then -- If player is in driver seat.
			adjustDoorDriverWindow = emGUI:dxCreateWindow(0.66, 0.51, 0.14, 0.19, "Adjust Doors", true)

			local labelDriver = emGUI:dxCreateLabel(0.05, 0.05, 0.43, 0.09, "Driver Door", true, adjustDoorDriverWindow)
			local scrollbarDriver = emGUI:dxCreateScrollBar(0.05, 0.18, 0.88, 0.12, true, true, adjustDoorDriverWindow)
			emGUI:dxSetFont(labelDriver, buttonFont_14)
			addEventHandler("onDgsScrollBarScrollPositionChange", scrollbarDriver, function(toState) setVehicleDoorOpenRatio(theVehicle, 2, toState / 100) end)

			local labelHood = emGUI:dxCreateLabel(0.05, 0.35, 0.43, 0.09, "Hood", true, adjustDoorDriverWindow)
			local scrollbarHood = emGUI:dxCreateScrollBar(0.05, 0.48, 0.88, 0.12, true, true, adjustDoorDriverWindow)
			emGUI:dxSetFont(labelHood, buttonFont_14)
			addEventHandler("onDgsScrollBarScrollPositionChange", scrollbarHood, function(toState) setVehicleDoorOpenRatio(theVehicle, 0, toState / 100) end)

			local labelTrunk = emGUI:dxCreateLabel(0.05, 0.66, 0.43, 0.09, "Trunk", true, adjustDoorDriverWindow)
			local scrollbarTrunk = emGUI:dxCreateScrollBar(0.05, 0.79, 0.88, 0.12, true, true, adjustDoorDriverWindow)
			emGUI:dxSetFont(labelTrunk, buttonFont_14)
			addEventHandler("onDgsScrollBarScrollPositionChange", scrollbarTrunk, function(toState) setVehicleDoorOpenRatio(theVehicle, 1, toState / 100) end)

			emGUI:dxScrollBarSetScrollBarPosition(scrollbarDriver, getVehicleDoorOpenRatio(theVehicle, 2) * 100)
			emGUI:dxScrollBarSetScrollBarPosition(scrollbarHood, getVehicleDoorOpenRatio(theVehicle, 0) * 100)
			emGUI:dxScrollBarSetScrollBarPosition(scrollbarTrunk, getVehicleDoorOpenRatio(theVehicle, 1) * 100)
		else
			-- Single door UI.
			adjustDoorWindowSingle = emGUI:dxCreateWindow(0.70, 0.40, 0.14, 0.10, "Adjust Doors", true)

			doorLabel = emGUI:dxCreateLabel(0.06, 0.2, 0.43, 0.17, doorNames[seatID], true, adjustDoorWindowSingle)
			emGUI:dxSetFont(doorLabel, buttonFont_14)

			scrollbar = emGUI:dxCreateScrollBar(0.06, 0.5, 0.88, 0.25, true, true, adjustDoorWindowSingle)
			addEventHandler("onDgsScrollBarScrollPositionChange", scrollbar, function(toState) setVehicleDoorOpenRatio(theVehicle, seatID + 2, toState / 100) end)

			emGUI:dxScrollBarSetScrollBarPosition(scrollbar, getVehicleDoorOpenRatio(theVehicle, seatID + 2) * 100)
		end
		return
	end

	-- Full menu.
	adjustDoorWindow = emGUI:dxCreateWindow(0.70, 0.41, 0.14, 0.34, "Adjust Doors", true)

	labels[1] = 	emGUI:dxCreateLabel(0.09, 0.04, 0.40, 0.05, "Hood", true, adjustDoorWindow)
	scrollbars[1] = emGUI:dxCreateScrollBar(0.09, 0.11, 0.83, 0.06, true, true, adjustDoorWindow)

	labels[2] = 	emGUI:dxCreateLabel(0.09, 0.19, 0.40, 0.05, "Trunk", true, adjustDoorWindow)
	scrollbars[2] = emGUI:dxCreateScrollBar(0.09, 0.26, 0.83, 0.06, true, true, adjustDoorWindow)

	labels[3] = 	emGUI:dxCreateLabel(0.09, 0.34, 0.40, 0.05, "Driver Door", true, adjustDoorWindow)
	scrollbars[3] = emGUI:dxCreateScrollBar(0.09, 0.41, 0.83, 0.06, true, true, adjustDoorWindow)

	labels[4] = 	emGUI:dxCreateLabel(0.09, 0.49, 0.40, 0.05, "Passenger Door", true, adjustDoorWindow)
	scrollbars[4] = emGUI:dxCreateScrollBar(0.09, 0.56, 0.83, 0.06, true, true, adjustDoorWindow)

	labels[5] = 	emGUI:dxCreateLabel(0.09, 0.64, 0.40, 0.05, "Rear Left Door", true, adjustDoorWindow)
	scrollbars[5] = emGUI:dxCreateScrollBar(0.09, 0.71, 0.83, 0.06, true, true, adjustDoorWindow)

	labels[6] = 	emGUI:dxCreateLabel(0.09, 0.79, 0.40, 0.05, "Rear Right Door", true, adjustDoorWindow)
	scrollbars[6] = emGUI:dxCreateScrollBar(0.09, 0.86, 0.83, 0.06, true, true, adjustDoorWindow)

	for i = 1, 6 do
		emGUI:dxSetFont(labels[i], buttonFont_14)
		-- Is setVehicleDoorOpenRatio synced? If not then setup serverside trigger.
		addEventHandler("onDgsScrollBarScrollPositionChange", scrollbars[i], function(toState) setVehicleDoorOpenRatio(theVehicle, i - 1, toState / 100) end)
	end

	for i = 0, 5 do emGUI:dxScrollBarSetScrollBarPosition(scrollbars[i + 1], getVehicleDoorOpenRatio(theVehicle, i) * 100) end
end
addEvent("vehicle:showDoorAdjusterGUI", true)
addEventHandler("vehicle:showDoorAdjusterGUI", root, showDoorAdjusterGUI)