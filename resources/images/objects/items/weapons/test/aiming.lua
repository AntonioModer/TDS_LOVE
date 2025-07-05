return function(selfSprite)
	selfSprite.transform.origin.x = -5
	selfSprite.transform.origin.y = -10
	selfSprite.transform.angle = -0.785398
	selfSprite.userdata = {}
	selfSprite.userdata.shootPoint = math.point(selfSprite.image:getWidth(), selfSprite.image:getHeight()/2)
end