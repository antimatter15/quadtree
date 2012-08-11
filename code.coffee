canvas = document.getElementById('c')
c = canvas.getContext('2d')
size = 1024
canvas.width = canvas.height = size


# document.body.onclick = (e) ->
# 	console.log 'click'
# 	c.fillRect e.clientX - 20, e.clientY - 20, 40, 40
c.fillStyle = '#007fff'
for i in [0...15]
	x = Math.random() * size
	y = Math.random() * size
	w = Math.random() * 10 + 10
	c.fillRect x - w, y - w, w * 2, w * 2

pixels = c.getImageData(0, 0, size, size).data

# maintain a list of permutations to try out randomly later on
# this is important because without trying out permutations randomly
# it's more likely to scan the wrong pixels.

permutations = [[0,1,2,3],[0,1,3,2],[0,2,1,3],[0,2,3,1],[0,3,1,2],[0,3,2,1],
				[1,0,3,2],[1,0,2,3],[1,2,3,0],[1,2,0,3],[1,3,2,0],[1,3,0,2],
				[2,0,1,3],[2,0,3,1],[2,1,0,3],[2,1,3,0],[2,3,0,1],[2,3,1,0],
				[3,0,2,1],[3,0,1,2],[3,1,2,0],[3,1,0,2],[3,2,1,0],[3,2,0,1]]

searched = 0
divideQuadrants = (x, y, w, h) ->
	if w <= 1 or h <= 1
		searched++
		return pixels[4 * (y * size + x) + 3] > 0
	# c.strokeRect x, y, w, h
	# quads = [[x, y], [x + w / 2, y], [x + w / 2, y + h / 2], [x, y + h / 2]]
	pos = 0
	neg = 0
	for k in permutations[Math.floor(24 * Math.random())]
		# [0, 0], [0, 1], [1, 0], [1, 1] is actually just binary
		# so what can we do? just take the number and modulo/divide
		# and use that to get the quadrant ID

		i = x + ((k % 2) * w / 2)
		j = y + (Math.floor(k / 2) * h / 2)

		# for [i, j] in quads
		if divideQuadrants(i, j, w / 2, h / 2) == true
			pos++
		else
			neg++
		if pos >= 2
			# console.log x, y, w, h
			c.strokeRect x, y, w, h
			return true
		if neg >= 2 and (w < 20 or h < 20)
		 	return false #cant have pos = 3 if neg = 2

test = ->
	console.time("start")
	divideQuadrants(0, 0, size, size)
	console.timeEnd("start")

	console.log("searched", searched/(size*size))

setTimeout test, 500