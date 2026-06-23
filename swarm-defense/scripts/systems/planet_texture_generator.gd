class_name PlanetTextureGenerator
extends RefCounted

enum PlanetType { MERCURY, VENUS, EARTH, MARS, MOON, GAS_GIANT, ICE_WORLD, LAVA_WORLD }

const TEXTURE_SIZE := 512

static func generate_texture(planet_type: PlanetType, seed_value: int, frequency: float = 3.0) -> ImageTexture:
    var noise = FastNoiseLite.new()
    noise.seed = seed_value
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = frequency
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = 0.5

    var detail_noise = FastNoiseLite.new()
    detail_noise.seed = seed_value + 1000
    detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
    detail_noise.frequency = frequency * 4.0
    detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    detail_noise.fractal_octaves = 3
    detail_noise.fractal_lacunarity = 2.0
    detail_noise.fractal_gain = 0.3

    noise.domain_warp_enabled = true
    noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
    noise.domain_warp_amplitude = 8.0
    noise.domain_warp_frequency = 2.0

    var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE / 2, false, Image.FORMAT_RGBA8)

    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var u = float(x) / float(image.get_width())
            var v = float(y) / float(image.get_height())

            var theta = u * TAU
            var phi = v * PI

            var nx = sin(phi) * cos(theta)
            var ny = sin(phi) * sin(theta)
            var nz = cos(phi)

            var n = noise.get_noise_3d(nx, ny, nz)
            var d = detail_noise.get_noise_3d(nx, ny, nz)

            var color = _get_planet_color(planet_type, n, d)
            image.set_pixel(x, y, color)

    return ImageTexture.create_from_image(image)

static func _get_planet_color(type: PlanetType, noise_val: float, detail: float) -> Color:
    var h = noise_val * 0.5 + 0.5
    h = clamp(h + detail * 0.15, 0.0, 1.0)

    match type:
        PlanetType.MERCURY:
            return _color_ramp(h, [
                [0.0, Color(0.35, 0.32, 0.30)],
                [0.3, Color(0.40, 0.37, 0.34)],
                [0.5, Color(0.45, 0.42, 0.38)],
                [0.7, Color(0.50, 0.47, 0.43)],
                [0.85, Color(0.42, 0.39, 0.35)],
                [1.0, Color(0.38, 0.35, 0.32)],
            ])

        PlanetType.VENUS:
            var swirl = noise_val * 0.5 + 0.5
            var base = Color(0.85, 0.72, 0.40)
            var light = Color(0.95, 0.85, 0.55)
            var dark = Color(0.70, 0.55, 0.30)
            return base.lerp(light, swirl * 0.6).lerp(dark, (1.0 - swirl) * 0.3)

        PlanetType.EARTH:
            var ocean_level = 0.45
            if h < ocean_level:
                var ocean_depth = h / ocean_level
                var shallow = Color(0.05, 0.30, 0.55)
                var deep = Color(0.01, 0.08, 0.20)
                var ocean_color = deep.lerp(shallow, ocean_depth)
                var foam = Color(0.6, 0.7, 0.8) if ocean_depth > 0.9 and detail > 0.3 else ocean_color
                return ocean_color.lerp(foam, 0.1 if ocean_depth > 0.9 else 0.0)
            else:
                var land_h = (h - ocean_level) / (1.0 - ocean_level)
                var beach = Color(0.55, 0.50, 0.30)
                var grass = Color(0.15, 0.40, 0.10)
                var forest = Color(0.08, 0.25, 0.05)
                var mountain = Color(0.40, 0.35, 0.25)
                var snow = Color(0.90, 0.92, 0.95)

                if land_h < 0.15:
                    return beach.lerp(grass, land_h / 0.15)
                elif land_h < 0.50:
                    var t = (land_h - 0.15) / 0.35
                    return grass.lerp(forest, t)
                elif land_h < 0.80:
                    var t = (land_h - 0.50) / 0.30
                    return forest.lerp(mountain, t)
                else:
                    var t = (land_h - 0.80) / 0.20
                    return mountain.lerp(snow, t)

        PlanetType.MARS:
            return _color_ramp(h, [
                [0.0, Color(0.35, 0.18, 0.10)],
                [0.2, Color(0.50, 0.25, 0.12)],
                [0.4, Color(0.60, 0.30, 0.14)],
                [0.6, Color(0.70, 0.38, 0.18)],
                [0.8, Color(0.55, 0.28, 0.12)],
                [1.0, Color(0.80, 0.45, 0.22)],
            ])

        PlanetType.MOON:
            return _color_ramp(h, [
                [0.0, Color(0.42, 0.40, 0.38)],
                [0.3, Color(0.50, 0.48, 0.45)],
                [0.5, Color(0.55, 0.52, 0.48)],
                [0.7, Color(0.50, 0.47, 0.43)],
                [0.85, Color(0.45, 0.42, 0.38)],
                [1.0, Color(0.48, 0.45, 0.42)],
            ])

        _:
            return Color.WHITE

static func _color_ramp(t: float, stops: Array) -> Color:
    if stops.is_empty():
        return Color.WHITE
    if len(stops) == 1:
        return stops[0][1]
    if t <= stops[0][0]:
        return stops[0][1]
    if t >= stops[-1][0]:
        return stops[-1][1]

    for i in range(len(stops) - 1):
        if t >= stops[i][0] and t < stops[i + 1][0]:
            var local_t = (t - stops[i][0]) / (stops[i + 1][0] - stops[i][0])
            return stops[i][1].lerp(stops[i + 1][1], local_t)

    return stops[-1][1]

static func get_atmosphere_color(type: PlanetType) -> Color:
    match type:
        PlanetType.EARTH:
            return Color(0.4, 0.6, 1.0, 0.15)
        PlanetType.VENUS:
            return Color(0.9, 0.7, 0.3, 0.20)
        PlanetType.MARS:
            return Color(0.8, 0.5, 0.3, 0.08)
        _:
            return Color.TRANSPARENT

static func has_atmosphere(type: PlanetType) -> bool:
    return type in [PlanetType.EARTH, PlanetType.VENUS, PlanetType.MARS]
