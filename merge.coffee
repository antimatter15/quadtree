canvas = document.getElementById('c')
c = canvas.getContext('2d')
size = 1024
canvas.width = canvas.height = size


# document.body.onclick = (e) ->
# 	console.log 'click'
# 	c.fillRect e.clientX - 20, e.clientY - 20, 40, 40
c.fillStyle = '#007fff'
for i in [0...290]
	x = Math.random() * size
	y = Math.random() * size
	w = Math.random() * 8 + 1
	c.fillRect (x - w) + .5, (y - w) + .5, w * 2, w * 2

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
	if amax - asum > Math.pow(40, 2) 
		return null

	# if it's worth merging, give it a mergability score
	return [waste, bound]

divideQuadrants = (x, y, w, h) ->
	if w is 1 and h is 1
		if pixels[4 * (y * size + x) + 3] > 0
			return [[x, y, 1, 1, 0]]
		else
			return []

	# 
	# c.strokeRect x, y, w, h
	# quads = [[x, y], [x + w / 2, y], [x + w / 2, y + h / 2], [x, y + h / 2]]
	
	boxes = []

	for k in [0, 1, 2, 3] # all of the quadrants
		i = x + ((k % 2) * w / 2)
		j = y + (Math.floor(k / 2) * h / 2)

		# for [i, j] in quads
		boxes = boxes.concat divideQuadrants(i, j, w / 2, h / 2)
	
	# merge boxes!
	while true #loop until it's done
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

		[score, bound, a, b] = sorted[0]
		boxes = (box for box in boxes when box isnt a and box isnt b)
		boxes.push bound
		# console.log boxes

	return boxes
c.strokeStyle = "black"
console.time("merge")
parts = divideQuadrants(0, 0, size, size)
console.timeEnd("merge")
for [x, y, w, h, e] in parts
	console.log x, y, w, h, e / (w * h)
	c.strokeRect x + 0.5, y+ 0.5, w, h
