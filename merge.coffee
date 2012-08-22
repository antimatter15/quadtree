canvas = document.getElementById('c')
c = canvas.getContext('2d')
size = 2048
canvas.width = canvas.height = size

rng_state = 123
rand = ->
	rng_state = (1103515245 * rng_state + 12345) % 0x100000000
	return rng_state / 0x100000000

# document.body.onclick = (e) ->
# 	console.log 'click'
# 	c.fillRect e.clientX - 20, e.clientY - 20, 40, 40
c.fillStyle = '#007fff'
for i in [0...490]
	x = rand() * size
	y = rand() * size
	w = rand() * 4 + 1
	c.fillRect (x - w) + .5, (y - w) + .5, w * 2, w * 2

# c.fillRect 100, 100, 100, 100
# c.fillRect 600, 600, 100, 100

pixels = c.getImageData(0, 0, size, size).data


#get combinations that have two elements from a list
combinations = (list) ->
	newlist = []
	for a in [0...list.length]
		for b in [0...a]
			newlist.push [list[a], list[b]]
	newlist


weightMerger = ([x1, y1, w1, h1, waste1], [x2, y2, w2, h2, waste2]) ->
	# calculate the bounding box
	minx = Math.min x1, x2
	miny = Math.min y1, y2
	maxx = Math.max (x1 + w1), (x2 + w2)
	maxy = Math.max (y1 + h1), (y2 + h2)
	maxw = maxx - minx
	maxh = maxy - miny
	# calculate the areas
	a1 = w1 * h1
	a2 = w2 * h2
	asum = a1 + a2
	amax = maxw * maxh
	
	# there are cases when asum > amax, such as when there's an overlap
	# calculate waste, the metric being used to find what to merge first
	waste = waste1 + waste2 + Math.max(0, amax - asum)

	bound = [minx, miny, maxw, maxh, waste]

	# check if the rectangles overlap, in which case you merge immediately
	unless (y1 + h1) < y2 or y1 > (y2 + h2) or (x1 + w1) < x2 or x1 > (x2 + w2)
		return [-1, bound] 

	# compare the areas to see if it's worth merging
	# or waste / (maxw * maxh) < 0.5
	if amax - asum < Math.pow(20, 2) 
		return [waste, bound]

	# aww no merging for you
	return null

merges = 0
layers = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
divideQuadrants = (x, y, w, h) ->
	if w is 1 and h is 1
		if pixels[4 * (y * size + x) + 3] > 0
			return [[x, y, 1, 1, 0]]
		else
			return []
	# 

	# 
	# c.strokeRect x, y, w, h
	# quads = [[x, y], [x + w / 2, y], [x + w / 2, y + h / 2], [x, y + h / 2]]
	
	# boxes = []
	# for k in [0, 1, 2, 3] # all of the quadrants
	# 	i = x + ((k % 2) * w / 2)
	# 	j = y + (Math.floor(k / 2) * h / 2)

	# 	# for [i, j] in quads
	# 	boxes = boxes.concat divideQuadrants(i, j, w / 2, h / 2)

	start = +new Date
	hw = w >> 1
	hh = h >> 1
	boxes = [].concat divideQuadrants(x, y, hw, hh),
		divideQuadrants(x + hw, y, hw, hh),
		divideQuadrants(x + hw, y + hh, hw, hh),
		divideQuadrants(x, y + hh, hw, hh)

	layers[Math.log(w) / Math.log(2) - 1] += new Date - start
	# merge boxes!
	while boxes.length > 1 #loop until it's done
		# try to 	
		pairs = for [a, b] in combinations(boxes)
			weight = weightMerger(a, b)
			if weight
				weight.concat([a, b])
			else
				null

		pairs = (pair for pair in pairs when pair isnt null)

		break if pairs.length is 0

		sorted = pairs.sort (a, b) ->
			return a[0] - b[0]

		merges++

		[score, bound, a, b] = sorted[0]
		boxes = (box for box in boxes when box isnt a and box isnt b)
		boxes.push bound
		# console.log boxes
	return boxes


reference = (w, h) ->
	filled = 0
	for x in [0...w]
		for y in [0...h]
			if pixels[4 * (y * size + x) + 3] > 0
				filled++
	return filled


recursion = (x, y, w, h) ->
	if w is 1 and h is 1
		if pixels[4 * (y * size + x) + 3] > 0
			return 1
		else
			return 0
	hw = w >> 1
	hh = h >> 1
	return recursion(x, y, hw, hh) +
	recursion(x + hw, y, hw, hh) + 
	recursion(x + hw, y + hh, hw, hh) + 
	recursion(x, y + hh, hw, hh)


basictree = (x, y, w, h) ->
	if w is 1 and h is 1
		if pixels[4 * (y * size + x) + 3] > 0
			return [[x, y, 1, 1, 0]]
		else
			return []
	hw = w >> 1
	hh = h >> 1
	boxes = [].concat basictree(x, y, hw, hh),
		basictree(x + hw, y, hw, hh),
		basictree(x + hw, y + hh, hw, hh),
		basictree(x, y + hh, hw, hh)

	return []


c.strokeStyle = "black"
console.time("filled")
console.log 'fill', reference(size, size)
console.timeEnd("filled")


console.time("recursion")
console.log 'recur', recursion(0, 0, size, size)
console.timeEnd("recursion")


console.time("tree")
console.log 'basic', basictree(0, 0, size, size).length
console.timeEnd("tree")

console.time("merge")
parts = divideQuadrants(0, 0, size, size)
console.timeEnd("merge")
for [x, y, w, h, e] in parts
	# console.log x, y, w, h, e / (w * h)
	c.strokeRect x + 0.5, y+ 0.5, w, h
