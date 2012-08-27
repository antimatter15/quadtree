canvas = document.getElementById('c')
c = canvas.getContext('2d')
# size = 512
width = 1024
height = 1024
canvas.width = width
canvas.height = height
#3598307628
seed = Math.floor(Math.random() * 0x100000000)
rng_state = seed
rand = ->
	return Math.random()
	rng_state = (1103515245 * rng_state + 12345) % 0x100000000
	return rng_state / 0x100000000


Math.max = (a, b) -> return (if a > b then a else b)

# document.body.onclick = (e) ->
# 	console.log 'click'
# 	c.fillRect e.clientX - 20, e.clientY - 20, 40, 40
c.fillStyle = '#007fff'
for i in [0...5]
	x = rand() * width
	y = rand() * height
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

c.fillRect 10, 10, 100, 600
c.fillRect 110, 10, 600, 100
# c.fillRect 600, 600, 100, 100

pixels = c.getImageData(0, 0, width, height).data


#get combinations that have two elements from a list
combinations = (list) ->
	newlist = []
	for a in [0...list.length]
		for b in [0...a]
			newlist.push [list[a], list[b]]
	newlist


getPixel = (x, y) ->
	return pixels[4 * (y * width + x) + 3] > 0


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

	for [i, j] in sched
		# if this kind of thing wouldnt advance the frontier, why bother
		if xmin <= i <= xmax and ymin <= j <= ymax
			continue
		if getPixel(x + i, y + j)
			xmin = Math.min(xmin, i)
			xmax = Math.max(xmax, i)
			ymin = Math.min(ymin, j)
			ymax = Math.max(ymax, j)

	return [] if ymax < 0
	return [[x + xmin, y + ymin, xmax - xmin, ymax - ymin, 0]]



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
		# bound[4] = 0
		return [-1, bound] 

	# compare the areas to see if it's worth merging
	# or waste / (maxw * maxh) < 0.5
	# squareness = 1 + Math.pow(maxw - maxh, 2) / 1000
	if dist < 20 and asum / amax > 0.8
		return [waste, bound]

	# if (amax - asum) < 10
	# 	return [waste, bound]

	# aww no merging for you
	return null



divideQuadrants = (x, y, size) ->
	if size is 4
		return smallBoundingBox(x, y)
	# console.log size
	half = size >> 1
	mx = x + half
	my = y + half
	
	boxes = divideQuadrants(x, y, half).concat divideQuadrants(mx, y, half),
		divideQuadrants(mx, my, half),
		divideQuadrants(x, my, half)

	skipbox = []
	bound = 32

	# optimization for the bigger squares to prevent the weird combinatorial explosion
	# if the size is less than four times the bound, it's quite unlikely to find anything
	# which actually is worth skipping, so it's faster just to skip over this step
	# and go straight for the merging
	if size > bound * 4
		boxtmp = boxes
		boxes = []

		for box in boxtmp
			[x1, y1, w1, h1, waste1] = box
			# check to see if the box is close to the middle axes, here's a pretty lame ASCII 
			# art representation of the exclusion boundary

			# - - X X X - -
			# - - X X X - -
			# X X X X X X X
			# X X X X X X X
			# X X X X X X X
			# - - X X X - -
			# - - X X X - -

			# see, the X represents the region which will always be fed into the boxes
			# list because this represents the region of stuff which might be merged
			# together. the region denoted by the little dashes is the region which 
			# can pretty much be left unprocessed.

			# the definition of the exclusion boundary is the distance from the axis
			# to be left alone. Note that if it's something really big and it's mostly
			# in the ignored region but touches slightly into that close-to-axis region
			# it can't be ignored and still has to be processed.

			# in theory, this exclusion boundary should be the same as the one in the 
			# merger weighting algorithm
			if Math.abs(x1 - mx) < bound or Math.abs(x1 + w1 - mx) < bound or Math.abs(y1 - my) < bound or Math.abs(y1 + h1 - my) < bound
				boxes.push box
			else
				skipbox.push box


		# console.log 'skipping', skipbox.length, boxes.length

	# merge boxes! this is the most important part of the whole operation
	# the pièce de résistance. It's cool, man. Really cool.

	while boxes.length > 1 #loop until it's done
		
		# get a list of combinations of boxes (pairs of two boxes)
		# and that means there's 1/2(n - 1) * n combinations (n^2) for 
		# n of these boxes, which is what leads to that combinatorial
		# explosion that we so dearingly fear.
		# but of course the skipping of boxes as done above really
		# sort of helps in reducing that pool

		# we're going to sort it to make sure things are done in 
		# the right order, but that's not to say there's an actual
		# correct order to do things
		pairs = for [a, b] in combinations(boxes)
			weight = weightMerger(a, b)
			if weight
				weight.concat([a, b])
			else
				null

		# go a second pass through the stuff and filter out crap 
		# which doesn't belong

		pairs = (pair for pair in pairs when pair isnt null)

		# in case that yields a null set, terminate because we're done here

		break if pairs.length is 0

		# I'm not totally sure that sorting it is absolutely necessarily
		# and whether or not this is actually worth it. I'm not sure of any
		# concrete instance of whether or not this actually improves the 
		# result or how extensively it slows down the process. 
		pairs = pairs.sort (a, b) ->
			return a[0] - b[0]

		# merges++

		[score, bound, a, b] = pairs[0]
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


	c.strokeStyle = 'red'
	c.lineWidth = 1
	# c.lineWidth = Math.log(w)/Math.log(2) - 3
	for [x, y, w, h, e] in boxes
		# console.log x, y, w, h, e / (w * h)
		c.strokeRect x + 0.5, y+ 0.5, w, h
	# layers[Math.log(w) / Math.log(2) - 1] += new Date - start
	# layers[Math.log(w) / Math.log(2) - 1] += boxes.length
	return boxes.concat skipbox


# reference = (w, h) ->
# 	filled = 0
# 	for x in [0...w]
# 		for y in [0...h]
# 			if pixels[4 * (y * size + x) + 3] > 0
# 				filled++
# 	return filled

drawgrid = (x, y, w, h) ->
	return if w is 4	
	c.strokeStyle = 'rgba(0,0,0,0.1)'
	c.strokeRect x, y, w, h
	c.strokeStyle = 'black'
	hw = w >> 1
	hh = h >> 1
	drawgrid(x, y, hw, hh)
	drawgrid(x + hw, y, hw, hh)
	drawgrid(x + hw, y + hh, hw, hh)
	drawgrid(x, y + hh, hw, hh)


# recursion = (x, y, w, h) ->
# 	if w is 1 and h is 1
# 		if pixels[4 * (y * size + x) + 3] > 0
# 			return 1
# 		else
# 			return 0
# 	hw = w >> 1
# 	hh = h >> 1
# 	return recursion(x, y, hw, hh) +
# 	recursion(x + hw, y, hw, hh) + 
# 	recursion(x + hw, y + hh, hw, hh) + 
# 	recursion(x, y + hh, hw, hh)


# basictree = (x, y, w, h) ->
# 	# if w is 4 and h is 4
# 	# 	return smallBoundingBox(x, y)

# 	if w is 1 and h is 1
# 		if pixels[4 * (y * size + x) + 3] > 0
# 			return [[x, y, 1, 1, 0]]
# 		else
# 			return []
# 	hw = w >> 1
# 	hh = h >> 1
# 	boxes = basictree(x, y, hw, hh).concat basictree(x + hw, y, hw, hh),
# 	basictree(x + hw, y + hh, hw, hh),
# 	basictree(x, y + hh, hw, hh)

# 	return boxes


# c.strokeStyle = "black"
# console.time("filled")
# console.log 'fill', reference(size, size)
# console.timeEnd("filled")


# console.time("recursion")
# console.log 'recur', recursion(0, 0, size, size)
# console.timeEnd("recursion")

drawgrid(0, 0, width, height)

# console.time("tree")
# console.log 'basic', basictree(0, 0, size, size).length
# console.timeEnd("tree")

console.time("merge")
parts = divideQuadrants(0, 0, width)
console.timeEnd("merge")

c.strokeStyle = 'green'
c.lineWidth = 2
for [x, y, w, h, e] in parts
	# console.log x, y, w, h, e / (w * h)
	c.strokeRect x + 0.5, y+ 0.5, w, h

# console.time('intersect')
# for [[x1, y1, w1, h1, waste1], [x2, y2, w2, h2, waste2]] in combinations(parts)
# 	unless (y1 + h1) < y2 or y1 > (y2 + h2) or (x1 + w1) < x2 or x1 > (x2 + w2)
# 		console.log 'intersection'
# console.timeEnd('intersect')