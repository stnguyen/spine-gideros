------------------------------------------------------------------------------
 -- Spine Runtime Software License - Version 1.0
 -- 
 -- Copyright (c) 2013, Esoteric Software
 -- All rights reserved.
 -- 
 -- Redistribution and use in source and binary forms in whole or in part, with
 -- or without modification, are permitted provided that the following conditions
 -- are met:
 -- 
 -- 1. A Spine Essential, Professional, Enterprise, or Education License must
 --    be purchased from Esoteric Software and the license must remain valid:
 --    http://esotericsoftware.com/
 -- 2. Redistributions of source code must retain this license, which is the
 --    above copyright notice, this declaration of conditions and the following
 --    disclaimer.
 -- 3. Redistributions in binary form must reproduce this license, which is the
 --    above copyright notice, this declaration of conditions and the following
 --    disclaimer, in the documentation and/or other materials provided with the
 --    distribution.
 -- 
 -- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 -- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 -- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 -- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 -- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 -- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 -- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 -- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 -- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 -- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ------------------------------------------------------------------------------

local Bone = require "spine-lua.Bone"
local Slot = require "spine-lua.Slot"
local AttachmentLoader = require "spine-lua.AttachmentLoader"

local Skeleton = {}
function Skeleton.new (skeletonData)
	if not skeletonData then error("skeletonData cannot be nil", 2) end
	local self = group or Sprite.new() 
	
	self.data = skeletonData
	self.bones = {}
	self.slots = {}
	self.slotsByName = {}
	self.drawOrder = {}
	self.images = {}
	self.r = 1
	self.g = 1
	self.b = 1
	self.a = 1
	self.glowOn = false
	function self:updateWorldTransform()
		for i,bone in ipairs(self.bones) do
			bone:updateWorldTransform(self.flipX, self.flipY)	
		end
		
		for i,slot in ipairs(self.drawOrder) do
			if slot.attachment and slot.attachment.type == spine.AttachmentType.region then
				local attachment = slot.attachment			
				local image = self.images[slot.attachment]
				
				if not image then 
					image = self:createImage(slot.attachment) 
					self.images[slot.attachment] = image
					self.attachments = attachment
					self:addChild(image)	
					
					image.xScaleRatio = slot.attachment.width / image:getWidth()
					image.yScaleRatio = slot.attachment.height / image:getHeight()
				end
				
				if image then
					image.x = slot.bone.worldX + slot.attachment.x * slot.bone.m00 + slot.attachment.y * slot.bone.m01
					image.y = -(slot.bone.worldY + slot.attachment.x * slot.bone.m10 + slot.attachment.y * slot.bone.m11)
					image.rotation = -(slot.bone.worldRotation + slot.attachment.rotation)
					
					image.xScale =  (slot.bone.worldScaleX + attachment.scaleX - 1) * image.xScaleRatio
					image.yScale =  (slot.bone.worldScaleY + attachment.scaleY - 1) * image.yScaleRatio
										
					if self.flipX then
						image.xScale = -image.xScale
						image.rotation = -image.rotation
					end
					
					if self.flipY then
						image.yScale = -image.yScale
						image.rotation = -image.rotation
					end
					

					image:setPosition(image.x, image.y)
					image:setColorTransform(slot.r, slot.g, slot.b, slot.a)
					image:setRotation(image.rotation)
					image:setScale(image.xScale, image.yScale)
					if slot.data.additiveBlending then
						image:setBlendMode("add")
					else
						image:setBlendMode("alpha")
					end
				end
			end
		end
		
		if self.debug then
			for i,bone in ipairs(self.bones) do
				if not bone.line then
					
					--bone.line = display.newLine(0, 0, bone.data.length, 0) 
					bone.line = Shape.new()
					bone.line:setLineStyle(1, 0xff0000)
					
				end
				
				bone.line.x = bone.worldX
				bone.line.y = -bone.worldY
				bone.line.rotation = -bone.worldRotation
				
				if self.flipX then
					bone.line.xScale = -1
					bone.line.rotation = -bone.line.rotation
				else
					bone.line.xScale = 1
				end
				
				if self.flipY then
					bone.line.yScale = -1
					bone.line.rotation = -bone.line.rotation
				else
					bone.line.yScale = 1
				end
				
				--bone.line:setColor(255, 0, 0)
				--self:insert(bone.line)
				bone.line:beginPath()
				bone.line:moveTo(0, 0)
				bone.line:lineTo(bone.data.length, 0)
				bone.line:endPath()
				bone.line:setScale(bone.line.xScale, bone.line.yScale)
				bone.line:setRotation(bone.line.rotation)
				bone.line:setPosition(bone.line.x, bone.line.y)
				self:addChild(bone.line)
				
				if not bone.circle then 
					--bone.circle = display.newCircle(0, 0, 3) 
					bone.circle = Shape.new()
					--bone.circle:setLineStyle(1, 0x00ff00)
					bone.circle:setFillStyle(Shape.SOLID, 0x00ff00, 1)
				end
				
				bone.circle.x = bone.worldX
				bone.circle.y = -bone.worldY
				--bone.circle:setFillColor(0, 255, 0)
				--self:insert(bone.circle)
				
				local radius = 3
				local sides = 15
				local startAngle = 0
				local arcAngle = 1
				local angleStep = arcAngle / sides
				
				bone.circle:setPosition(bone.circle.x, bone.circle.y)
				
				local x = math.cos(startAngle * 2 * math.pi) * radius
				local y = math.sin(startAngle * 2 * math.pi) * radius
				
				bone.circle:beginPath()
				bone.circle:moveTo(x, y)
				
				for i = 1, sides do
					local angle = startAngle + i * angleStep
					
					bone.circle:lineTo(math.cos(angle * 2 * math.pi) * radius, math.sin(angle * 2 * math.pi) * radius)
				end
				
				bone.circle:endPath()
				
				self:addChild(bone.circle)
			end
		end
	end


	function self:setToSetupPose ()
		self:setBonesToSetupPose()
		self:setSlotsToSetupPose()
	end

	function self:setBonesToSetupPose ()
		for i,bone in ipairs(self.bones) do
			bone:setToSetupPose()
		end
	end

	function self:setSlotsToSetupPose ()
		for i,slot in ipairs(self.slots) do
			slot:setToSetupPose()
		end
	end

	function self:getRootBone ()
		return self.bones[1]
	end

	function self:findBone (boneName)
		if not boneName then error("boneName cannot be nil.", 2) end
		for i,bone in ipairs(self.bones) do
			if bone.data.name == boneName then return bone end
		end
		return nil
	end

	function self:findSlot (slotName)
		if not slotName then error("slotName cannot be nil.", 2) end
		return self.slotsByName[slotName]
	end

	function self:setSkin (skinName)
		local newSkin
		if skinName then
			newSkin = self.data:findSkin(skinName)
			if not newSkin then error("Skin not found: " .. skinName, 2) end
			if self.skin then
				-- Attach all attachments from the new skin if the corresponding attachment from the old skin is currently attached.
				for k,v in pairs(self.skin.attachments) do
					local attachment = v[3]
					local slotIndex = v[1]
					local slot = self.slots[slotIndex]
					if slot.attachment == attachment then
						local name = v[2]
						local newAttachment = newSkin:getAttachment(slotIndex, name)
						if newAttachment then slot:setAttachment(newAttachment) end
					end
				end
			end
		end
		self.skin = newSkin
	end

	function self:getAttachment (slotName, attachmentName)
		if not slotName then error("slotName cannot be nil.", 2) end
		if not attachmentName then error("attachmentName cannot be nil.", 2) end
		local slotIndex = skeletonData.slotNameIndices[slotName]
		if slotIndex == -1 then error("Slot not found: " .. slotName, 2) end
		if self.skin then
			local attachment = self.skin:getAttachment(slotIndex, attachmentName)
			if attachment then return attachment end
		end
		if self.data.defaultSkin then
			return self.data.defaultSkin:getAttachment(slotIndex, attachmentName)
		end
		return nil
	end

	function self:setAttachment (slotName, attachmentName)
		if not slotName then error("slotName cannot be nil.", 2) end
		for i,slot in ipairs(self.slots) do
			if slot.data.name == slotName then
				if not attachmentName then 
					slot:setAttachment(nil)
				else
					slot:setAttachment(self:getAttachment(slotName, attachmentName))
				end
				return
			end
		end
		error("Slot not found: " + slotName, 2)
	end

	function self:update (delta)
		self.time = self.time + delta
	end

	for i,boneData in ipairs(skeletonData.bones) do
		local parent
		if boneData.parent then parent = self.bones[spine.utils.indexOf(skeletonData.bones, boneData.parent)] end
		table.insert(self.bones, Bone.new(boneData, parent))
	end

	for i,slotData in ipairs(skeletonData.slots) do
		local bone = self.bones[spine.utils.indexOf(skeletonData.bones, slotData.boneData)]
		local slot = Slot.new(slotData, self, bone)
		table.insert(self.slots, slot)
		self.slotsByName[slot.data.name] = slot
		table.insert(self.drawOrder, slot)
	end

	return self
end
return Skeleton
