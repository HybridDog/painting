-- painting - in-game painting for minetest

-- THIS MOD CODE AND TEXTURES LICENSED
--            <3 TO YOU <3
--    UNDER TERMS OF WTFPL LICENSE

-- 2012, 2013, 2014 obneq aka jin xi
if minetest.get_modpath("mcl_core") then
    minetest.register_craft({
        output = 'painting:easel 1',
        recipe = {
            { '', 'mcl_core:wood', '' },
            { '', 'mcl_core:wood', '' },
            { 'mcl_core:stick','', 'mcl_core:stick' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_16 1',
        recipe = {
            { '', '', '' },
            { '', '', '' },
            { 'mcl_core:paper', '', '' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_32 1',
        recipe = {
            { '', '', '' },
            { 'mcl_core:paper', 'mcl_core:paper', '' },
            { 'mcl_core:paper', 'mcl_core:paper', '' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_64 1',
        recipe = {
            { 'mcl_core:paper', 'mcl_core:paper', 'mcl_core:paper' },
            { 'mcl_core:paper', 'mcl_core:paper', 'mcl_core:paper' },
            { 'mcl_core:paper', 'mcl_core:paper', 'mcl_core:paper' },
        }})
else
    minetest.register_craft({
        output = 'painting:easel 1',
        recipe = {
            { '', 'default:wood', '' },
            { '', 'default:wood', '' },
            { 'default:stick','', 'default:stick' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_16 1',
        recipe = {
            { '', '', '' },
            { '', '', '' },
            { 'default:paper', '', '' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_32 1',
        recipe = {
            { '', '', '' },
            { 'default:paper', 'default:paper', '' },
            { 'default:paper', 'default:paper', '' },
        }})

    minetest.register_craft({
        output = 'painting:canvas_64 1',
        recipe = {
            { 'default:paper', 'default:paper', 'default:paper' },
            { 'default:paper', 'default:paper', 'default:paper' },
            { 'default:paper', 'default:paper', 'default:paper' },
        }})
end
