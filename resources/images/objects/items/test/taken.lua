return function(selfSprite)
--	selfSprite.transform.origin.x = 0
--	selfSprite.transform.origin.y = selfSprite.image:getHeight()/2

	selfSprite.transform.origin.x = selfSprite.image:getWidth()/2
	selfSprite.transform.origin.y = selfSprite.image:getHeight()/2
end