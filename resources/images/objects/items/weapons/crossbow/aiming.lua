return function(selfSprite)
	selfSprite.transform.origin.x = 0
	selfSprite.transform.origin.y = 8
	selfSprite.transform.angle = -0.785398
	selfSprite.userdata = {}
	selfSprite.userdata.shootPoint = math.point(selfSprite.image:getWidth(), selfSprite.image:getHeight()/2)
end