local gui = require 'quickie'
local shine = require 'shine'

local effect_names = {
	"boxblur",
	"colorgradesimple",
	"desaturate",
	"filmgrain",
	"gaussianblur",
	"glowsimple",
	"posterize",
	"separate_chroma",
	"vignette"
}
local current, effects

function love.load()
	current = 'none'
	effects = {none = function(f) f() end}
	for _,v in ipairs(effect_names) do
		print(v)
		effects[v] = shine[v]()
	end

	imgs = {
		i = 1,
		love.graphics.newImage('haddaway.jpg'),
		love.graphics.newImage('inspector.png')
	}

	gui.core.style.color.normal.fg = {10,10,10}
	gui.core.style.color.normal.bg = {255,255,255, 250}
	gui.core.style.color.hot.fg    = {255,255,255}
	gui.core.style.color.hot.bg    = {100,100,100, 150}
	gui.core.style.color.active.fg = {255,255,255}
	gui.core.style.color.active.bg = {60,60,60, 200}
	gui.core.style.gradient:set(255,255)
	gui.core.style.Label = function(state, text, align, x,y,w,h)
		love.graphics.setColor(200,200,200)
		local f = assert(love.graphics.getFont())
		y = y + (h - f:getHeight(text))/2
		love.graphics.print(text, x,y)
	end
	gui.keyboard.disable()
end

local show_menu = false
local options
local function setval(effect, name)
	return function(v) effects[effect][name] = v end
end
local function setrgb(effect, name)
	return function(v)
		local r = options[effect].red.value
		local g = options[effect].green.value
		local b = options[effect].blue.value
		effects[effect][name] = {r,g,b}
	end
end
options = {
	none = {opts = {}},
	boxblur = { opts = {"radius", "radius_h", "radius_v"},
		radius_v = {value = 3, min = 1, max = 11, onHit = setval("boxblur", "radius_v")},
		radius_h = {value = 3, min = 1, max = 11, onHit = setval("boxblur", "radius_h")},
		radius = {value = 3, min = 1, max = 11, onHit = function(v)
			effects.boxblur.radius = v
			options.boxblur.radius_v.value = v
			options.boxblur.radius_h.value = v
		end},
		dump = function(o)
			return ("radius_v = %d, radius_h = %d"):format(o.radius_v.value, o.radius_h.value)
		end
	},
	colorgradesimple = { opts = {"red", "green", "blue"},
		red = {value = 1, min = 0, max = 3, onHit = setrgb("colorgradesimple", "grade")},
		green = {value = 1, min = 0, max = 3, onHit = setrgb("colorgradesimple", "grade")},
		blue = {value = 1, min = 0, max = 3, onHit = setrgb("colorgradesimple", "grade")},
		dump = function(o)
			return ("grade = {%.03f, %.03f, %.03f}"):format(o.red.value, o.green.value, o.blue.value)
		end
	},
	desaturate = { opts = {"strength", "red", "green", "blue"},
		strength = {value = 0.5, min = 0, max = 1, onHit = setval("desaturate", "strength")},
		red = {value = 255, min = 0, max = 255, onHit = setrgb("desaturate", "tint")},
		green = {value = 255, min = 0, max = 255, onHit = setrgb("desaturate", "tint")},
		blue = {value = 255, min = 0, max = 255, onHit = setrgb("desaturate", "tint")},
		dump = function(o)
			return ("strength = %.03f, tint = {%d,%d,%d}"):format(o.strength.value, o.red.value, o.green.value, o.blue.value)
		end
	},
	filmgrain = {opts = {"opacity", "grainsize"},
		opacity = {value = 0.5, min = 0, max = 1, onHit = setval("filmgrain", "opacity")},
		grainsize = {value = 1, min = 1, max = 20, onHit = setval("filmgrain", "grainsize")},
		dump = function(o)
			return ("opacity = %.03f, grainsize = %.3f"):format(o.opacity.value, o.grainsize.value)
		end
	},
	gaussianblur = {opts = {"sigma"},
		sigma = {value = 0.5, min = 0, max = 5, onHit = setval("gaussianblur", "sigma")},
		dump = function(o)
			return ("sigma = %.03f - Warning: recompiles shader on option change"):format(o.sigma.value)
		end
	},
	posterize = {opts = {"num_bands"},
		num_bands = {value = 1, min = 1, max = 30, onHit = setval("posterize", "num_bands")},
		dump = function(o)
			return ("num_bands = %d"):format(o.num_bands.value)
		end
	},
	separate_chroma = {opts = {"angle", "radius"},
		angle = {value = 0, min = 0, max = 2*math.pi, onHit = setval("separate_chroma", "angle")},
		radius = {value = 1, min = 0, max = 30, onHit = setval("separate_chroma", "radius")},
		dump = function(o)
			return ("angle = %.03f, radius = %d"):format(o.angle.value, o.radius.value)
		end
	},
	glowsimple = {opts = {"sigma", "min_luma"},
		sigma = {value = 5, min = 0, max = 10, onHit = setval("glowsimple", "sigma")},
		min_luma = {value = 0.7, min = 0, max = 1, onHit = setval("glowsimple", "min_luma")},
		dump = function(o)
			return ("sigma = %.03f, min_luma = %.03f - Warning: recompiles shader on changing sigma"):format(o.sigma.value, o.min_luma.value)
		end
	},
	vignette = {opts = {"radius", "softness", "opacity"},
		radius = {value = 1, min = 0, max = 1.5, onHit = setval("vignette", "radius")},
		softness = {value = 0.5, min = 0, max = 1, onHit = setval("vignette", "softness")},
		opacity = {value = 0.5, min = 0, max = 1, onHit = setval("vignette", "opacity")},
		dump = function(o)
			return ("radius = %.03f, softness = %.03f, opacity = %.03f"):format(o.radius.value, o.softness.value, o.opacity.value)
		end
	},
}

function love.update(dt)
	gui.group.push{grow='down', pos = {love.graphics.getWidth()-130,5}, size = {120,20}}
	if gui.Button{text = show_menu and "Hide" or "Effect"} then
		show_menu = not show_menu
	end
	if show_menu then
		current = gui.Button{text = "none", pos = {nil, 7}} and "none" or current
		for _,name in ipairs(effect_names) do
			current = gui.Button{text = name} and name or current
		end
		if gui.Button{text = "Switch Image", pos = {nil, 7}} then
			imgs.i = imgs.i % #imgs + 1
		end
	end
	gui.group.pop()

	if show_menu then
		gui.group.push{grow='right', pos = {10, love.graphics.getHeight()-30}, size = {120,20}}
		for _,k in ipairs(options[current].opts) do
			local v = options[current][k]
			gui.Label{text = k, size = {"tight"}}
			gui.Label{text = "", size = {5}}
			if gui.Slider{info = v} then
				v.onHit(v.value)
			end
			gui.Label{text = "", size = {20}}
		end
		gui.group.pop()
	end
end

function love.draw()
	effects[current](function()
		love.graphics.draw(imgs[imgs.i], 0,0)
	end)
	if show_menu and current ~= "none" then
		love.graphics.setColor(0,0,0,150)
		love.graphics.rectangle('fill', 5,love.graphics.getHeight()-35, love.graphics.getWidth()-10, 30)
		love.graphics.rectangle('fill', 5,5, love.graphics.getWidth()-140, 30)
		love.graphics.setColor(255,255,255)
		love.graphics.print(("FPS: %d - %s: %s"):format(love.timer.getFPS(), current, options[current]:dump()), 10, 14)
	end
	gui.core.draw()
end
