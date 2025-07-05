--========================= thisModule.zDBEL
test = test or {}
test.layers = {}
test.layers[1] = {}
test.layers[1].searchIndex = {}
test.layers[2] = {}
test.layers[2].searchIndex = {}
test.layers[3] = {}
test.layers[3].searchIndex = {}
test.entity1 = {i=1.1}
test.layers[1][1] = test.entity1
test.layers[1].searchIndex[test.entity1] = 1
test.entity2 = {i=1.2}
test.layers[1][2] = test.entity2
test.layers[1].searchIndex[test.entity2] = 2
test.entity3 = {i=1.3}
test.layers[1][3] = test.entity3
test.layers[1].searchIndex[test.entity3] = 3
test.entity4 = {i=2.1}
test.layers[2][1] = test.entity4
test.layers[2].searchIndex[test.entity4] = 1
test.entity5 = {i=2.2}
test.layers[2][2] = test.entity5
test.layers[2].searchIndex[test.entity5] = 2
test.entity6 = {i=2.3}
test.layers[2][3] = test.entity6
test.layers[2].searchIndex[test.entity6] = 3
test.entity7 = {i=3.1}
test.layers[3][1] = test.entity7
test.layers[3].searchIndex[test.entity7] = 1
test.entity8 = {i=3.2}
test.layers[3][2] = test.entity8
test.layers[3].searchIndex[test.entity8] = 2
test.entity9 = {i=3.3}
test.layers[3][3] = test.entity9
test.layers[3].searchIndex[test.entity9] = 3

-- delete entitys
test.layers[1][test.layers[1].searchIndex[test.entity2]] = false
test.layers[1].searchIndex[test.entity2] = nil
test.entity2 = nil

--test.layers[2][test.layers[2].searchIndex[test.entity4]] = false
--test.layers[2].searchIndex[test.entity4] = nil
--test.entity4 = nil
test.layers[2][test.layers[2].searchIndex[test.entity5]] = false
test.layers[2].searchIndex[test.entity5] = nil
test.entity5 = nil
--test.layers[2][test.layers[2].searchIndex[test.entity6]] = false
--test.layers[2].searchIndex[test.entity6] = nil
--test.entity6 = nil

test.layers[3][test.layers[3].searchIndex[test.entity8]] = false
test.layers[3].searchIndex[test.entity8] = nil
test.entity8 = nil

-- draw entitys
for i=-10, 10 do
	if test.layers[i] then
		for i1=1, #test.layers[i] do
			local entity = test.layers[i][i1]
			if entity then
				print(entity.i)
			end
		end
		for entity, i in pairs(test.layers[i].searchIndex) do
			print("\tsearchIndex:", entity, i)
		end		
	end
end