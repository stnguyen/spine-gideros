application:setBackgroundColor(0x00000)

local spine = require "spine-gideros.spine"

local json = spine.SkeletonJson.new()
json.scale = 1
local skeletonData = json:readSkeletonDataFile("data/spineboy.json")

local skeleton = spine.Skeleton.new(skeletonData)
function skeleton:createImage (attachment)
	-- Customize where images are loaded.
	local image = Bitmap.new(Texture.new("data/" .. attachment.name .. ".png"))
	image:setAnchorPoint(0.5, 0.5)
	return image
end
skeleton.x = 160
skeleton.y = 400
skeleton.flipX = false
skeleton.flipY = false
skeleton.debug = true -- Omit or set to false to not draw debug lines on top of the images.
skeleton:setToSetupPose()

skeleton:setPosition(skeleton.x, skeleton.y)

-- AnimationStateData defines crossfade durations between animations.
local stateData = spine.AnimationStateData.new(skeletonData)
stateData:setMix("walk", "jump", 0.2)
stateData:setMix("jump", "walk", 0.4)

-- AnimationState has a queue of animations and can apply them with crossfading.
local state = spine.AnimationState.new(stateData)
--state:setAnimationByName(0, "drawOrder")
--state:addAnimationByName(0, "jump", false, 0)
state:addAnimationByName(0, "walk", true, 0)

stage:addChild(skeleton)
-- END NEW

local lastTime = 0
local animationTime = 0

stage:addEventListener("enterFrame", function (event)

	-- Compute time in seconds since last frame.
	local currentTime = event.time -- / 1000
	local delta = currentTime - lastTime
	
	lastTime = currentTime

	-- Accumulate time and pose skeleton using animation.
	state:update(delta*0.5)
	state:apply(skeleton)
	skeleton:updateWorldTransform()
end)