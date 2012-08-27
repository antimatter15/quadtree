canvas = document.getElementById('c')
c = canvas.getContext('2d')
size = 2048
canvas.width = canvas.height = size
#3598307628
seed = Math.floor(Math.random() * 0x100000000)
rng_state = seed
rand = ->
	return Math.random()
	rng_state = (1103515245 * rng_state + 12345) % 0x100000000
	return rng_state / 0x100000000

# document.body.onclick = (e) ->
# 	console.log 'click'
# 	c.fillRect e.clientX - 20, e.clientY - 20, 40, 40
c.fillStyle = '#007fff'
for i in [0...100]
	x = rand() * size
	y = rand() * size
	w = rand() * 60 + 1
	for j in [0...w*w]
		ang = rand() * Math.PI * 2
		s = rand()
		cx = x + Math.sin(ang) * w * s
		cy = y + Math.cos(ang) * w * s
		c.fillRect cx, cy, 1, 1

	# for j in [0...(rand() * 60 + 1)]
	# 	for k in [0...(rand() * 60 + 1)]
	# 		if Math.random() > 0.7
	# 			c.fillRect x + j, y + k, 1, 1

c.fillRect 10, 10, 100, 100
# c.fillRect 600, 600, 100, 100

pixels = c.getImageData(0, 0, size, size).data


#get combinations that have two elements from a list
combinations = (list) ->
	newlist = []
	for a in [0...list.length]
		for b in [0...a]
			newlist.push [list[a], list[b]]
	newlist

# counter = 0
# max_core = (a, b) -> 
# 	counter++
# 	if a > b
# 		return a
# 	else
# 		return b

# max = (a, b) ->
# 	test = max_core(a, b)
# 	nat = Math.max(a, b)
# 	if test != nat
# 		console.log test, nat, a, b, counter
# 	return test

Math.max = (a, b) -> return (if a > b then a else b)

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

	# basically, this means that math.max isn't working	
	# if maxw < 0 or maxh < 0
	# 	console.log [x1, y1, w1, h1], [x2, y2, w2, h2], maxw, maxh, [maxx, maxy], [minx, miny]

	# there are cases when asum > amax, such as when there's an overlap
	# calculate waste, the metric being used to find what to merge first
	waste = waste1 + waste2 + Math.max(0, amax - asum)

	bound = [minx, miny, maxw, maxh, waste]

	dx = Math.max(x1, x2) - Math.min(x1 + w1, x2 + w2)
	dy = Math.max(y1, y2) - Math.min(y1 + h1, y2 + h2)
	dist = 0
	if dx < 0
		dist = Math.max(dy, 0)
	else if dy < 0
		dist = dx
	else
		dist = Math.sqrt(dx * dx + dy * dy)

	# check if the rectangles overlap, in which case you merge immediately
	unless (y1 + h1) < y2 or y1 > (y2 + h2) or (x1 + w1) < x2 or x1 > (x2 + w2)
		return [-1, bound] 

	# compare the areas to see if it's worth merging
	# or waste / (maxw * maxh) < 0.5
	# squareness = 1 + Math.pow(maxw - maxh, 2) / 1000
	if dist < 20
		return [waste, bound]

	# if (amax - asum) < 10
	# 	return [waste, bound]

	# aww no merging for you
	return null

# merges = 0
# layers = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]


getPixel = (x, y) ->
	return pixels[4 * (y * size + x) + 3] > 0

smallBoundingBox = (x, y) ->
	# this calculates the bounding box for a 4x4 block
	# why exactly? because at this point, merging and 
	# doing all that other crap becomes quite slow, well
	# its actually really fast, but since theres so much 
	# of it, that it's not worth doing, so here's the 
	# solution: special algorithm that calculates the
	# bounding box of this crap, the cool thing is that you
	# can actually save processing time woot by ignoring
	# certain pixels once you've established key regions

	# in an ideal example, if you have [0,0] and [3,3] marked
	# then you dont need to check the other 12 pixels because
	# you already know the bounds
	
	xmin = 5
	ymin = 5
	xmax = -1
	ymax = -1

	# TODO: put the rest of this in some optimal order
	# here is the described scheme
	
	# 01 03 07 11
	# 05 13 15 10
	# 09 16 14 06
	# 12 08 04 02

	# the important part is that it does the first two
	# which establishes the maximum possible bounding
	# area, and the others just seem like they're in
	# some sort of order that means something, but I
	# haven't honestly given enough thought to prove
	# this to be the case
	sched = [[0,0],[3,3], # these are important
			[0,1],[3,2],
			[1,0],[2,3],
			[0,2],[3,1],
			[2,0],[1,3],
			[0,3],[3,0],
			[1,1],[2,2],
			[1,2],[2,1]]

	for i in [0...4]
		for j in [0...4]
			# if this kind of thing wouldnt advance the frontier, why bother
			if xmin < i < xmax and ymin < j < ymax
				continue
			if getPixel(x + i, y + j)
				xmin = Math.min(xmin, i)
				xmax = Math.max(xmax, i)
				ymin = Math.min(ymin, j)
				ymax = Math.max(ymax, j)

	return [] if ymax < 0
	return [[x + xmin, y + ymin, xmax - xmin, ymax - ymin, 0]]




divideQuadrants = (x, y, w, h) ->
	if w is 4 and h is 4
		return smallBoundingBox(x, y)

	hw = w >> 1
	hh = h >> 1
	mx = x + hw
	my = y + hw
	start = +new Date

	boxes = [].concat divideQuadrants(x, y, hw, hh),
		divideQuadrants(mx, y, hw, hh),
		divideQuadrants(mx, my, hw, hh),
		divideQuadrants(x, my, hw, hh)

	# if w is 2 and h is 2 and boxes.length is 4
	# 	return [[x, y, 2, 2, 0]]

	c.strokeStyle = 'rgba(0,0,0,0.1)'
	c.strokeRect x, y, w, h
	c.strokeStyle = 'black'

	skipbox = []
	if w > 512
		# optimization for the bigger squares to prevent the weird combinatorial explosion

		
		boundary = 32
		
		# start at the 1/4 and end at 3/4 for little middle square

		# x2 = x + boundary
		# y2 = y + boundary

		# w2 = w - boundary * 2
		# h2 = h - boundary * 2


		boxtmp = boxes
		boxes = []

		for box in boxtmp
			[x1, y1, w1, h1, waste1] = box

			if Math.abs(x1 - mx) < boundary or Math.abs(x1 + w1 - mx) < boundary or Math.abs(y1 - my) < boundary or Math.abs(y1 + h1 - my) < boundary
				boxes.push box
			else
				# console.log('skip')
				skipbox.push box

			# if x1 > x2 and y1 > y2 and (x1 + w1) < (x2 + w2) and (y1 + h1) < (y2 + h2)
			# 	# bam, this square is wholly within the center of the box
			# 	# meaning that there is at least a w/4 merge boundary
			# 	skipbox.push box
			# else
			# 	boxes.push box


		# console.log 'skipping', skipbox.length, boxes.length

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

		# merges++

		[score, bound, a, b] = sorted[0]
		boxes = (box for box in boxes when box isnt a and box isnt b)
		boxes.push bound

		[x2, y2, w2, h2, waste2] = bound
		boxtmp = skipbox
		skipbox = []
		for box in boxtmp
			[x1, y1, w1, h1, waste1] = box
			unless (y1 + h1) < y2 or y1 > (y2 + h2) or (x1 + w1) < x2 or x1 > (x2 + w2)
				boxes.push box
				# console.log 'box returned'
			else
				skipbox.push box
		# console.log boxes

	
	# layers[Math.log(w) / Math.log(2) - 1] += new Date - start
	# layers[Math.log(w) / Math.log(2) - 1] += boxes.length
	return boxes.concat skipbox


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

	return boxes


# c.strokeStyle = "black"
# console.time("filled")
# console.log 'fill', reference(size, size)
# console.timeEnd("filled")


# console.time("recursion")
# console.log 'recur', recursion(0, 0, size, size)
# console.timeEnd("recursion")


# console.time("tree")
# console.log 'basic', basictree(0, 0, size, size).length
# console.timeEnd("tree")

console.time("merge")
parts = divideQuadrants(0, 0, size, size)
console.timeEnd("merge")

c.strokeStyle = 'green'
c.lineWidth = 2
for [x, y, w, h, e] in parts
	# console.log x, y, w, h, e / (w * h)
	c.strokeRect x + 0.5, y+ 0.5, w, h

for [[x1, y1, w1, h1, waste1], [x2, y2, w2, h2, waste2]] in combinations(parts)
	unless (y1 + h1) < y2 or y1 > (y2 + h2) or (x1 + w1) < x2 or x1 > (x2 + w2)
		console.log 'intersection'