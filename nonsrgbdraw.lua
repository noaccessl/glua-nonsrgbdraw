--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

	glua-nonsrgbdraw (https://github.com/noaccessl/glua-nonsrgbdraw/)
	 A non-sRGB draw library for Garry's Mod.

–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Globals
--
local surface = surface

--
-- Functions
--
local SurfaceSetDrawColor = surface.SetDrawColor
local SurfaceSetMaterial = surface.SetMaterial
local SurfaceDrawTexturedRect = surface.DrawTexturedRect
local SurfaceDrawTexturedRectUV = surface.DrawTexturedRectUV

local SurfaceSetFont = surface.SetFont

local SurfaceSetTextPos = surface.SetTextPos
local SurfaceSetTextColor = surface.SetTextColor
local SurfaceDrawText = surface.DrawText

local RenderPushTarget = render.PushRenderTarget
local RenderPopTarget = render.PopRenderTarget
local RenderClear = render.Clear

local CamEnd2D = cam.End2D

local tostring = tostring

local mathfloor = math.floor
local mathmin = math.min

local strfind = string.find
local strgsub = string.gsub
local strrep = string.rep

--
-- Enums
--
local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local IMAGE_FORMAT_I8 = 5
local IMAGE_FORMAT_A8 = 8


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Special variables
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local SCREEN_W = ScrW()
local SCREEN_H = ScrH()

local SCREEN_W_INV = 1 / ScrW()
local SCREEN_H_INV = 1 / ScrH()

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Rounds to the closest even
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function mathroundtoeven( num )

	num = mathfloor( num )

	return num + num % 2

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Init
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
nonsrgbdraw = nonsrgbdraw or {

	VERSION = 25042600 -- YY/MM/DD/##

}

local nonsrgbdraw = nonsrgbdraw


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Special RTs & materials
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function CreateNonSRGBMaterial( name, texture )

	return CreateMaterial(

		'nonsrgb/' .. name,
		'UnlitGeneric',
		{

			['$basetexture'] = texture;
			['$translucent'] = 1;
			['$vertexalpha'] = 1;
			['$vertexcolor'] = 1;
			['$gammacolorread'] = 1; -- Disables SRGB conversion of color texture read.
			['$linearwrite'] = 1 -- Disables SRGB conversion of shader results.

		}

	)

end

local RT_SMALL, MAT_SMALL; do

	RT_SMALL = GetRenderTargetEx(

		'_rt_NonSRGB_Small',
		1, 1,
		RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE,
		1 + 256 + 512, 0,
		IMAGE_FORMAT_I8

	)

	MAT_SMALL = CreateNonSRGBMaterial( '__small', '_rt_NonSRGB_Small' )

	RenderPushTarget( RT_SMALL )
		RenderClear( 255, 255, 255, 255 )
	RenderPopTarget()

end

local RT_BIG
local MAT_BIG

local function UPDATE_RT_BIG()

	RT_BIG = GetRenderTargetEx(

		Format( '_rt_NonSRGB_Big_%dx%d', SCREEN_W, SCREEN_H ),
		SCREEN_W, SCREEN_H,
		RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE,
		1 + 256 + 512, 0,
		IMAGE_FORMAT_A8

	)

end

local function INIT_MAT_BIG()

	MAT_BIG = CreateNonSRGBMaterial( '__big', RT_BIG:GetName() )

end

local function UPDATE_MAT_BIG()

	MAT_BIG:SetTexture( '$basetexture', RT_BIG )

end

UPDATE_RT_BIG()
INIT_MAT_BIG()

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Update internals
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
timer.Create( 'nonsrgbdraw_updateinternals', 0.618, 0, function()

	RenderPushTarget( RT_SMALL )
		RenderClear( 255, 255, 255, 255 )
	RenderPopTarget()

	local wScreen, hScreen = ScrW(), ScrH()

	if ( SCREEN_W == wScreen and SCREEN_H == hScreen ) then
		return
	end

	SCREEN_W = wScreen
	SCREEN_H = hScreen

	SCREEN_W_INV = 1 / wScreen
	SCREEN_H_INV = 1 / hScreen

	UPDATE_RT_BIG()
	UPDATE_MAT_BIG()

end )


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Cached surface.GetTextSize
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local CachedTextSize; do

	local SurfaceGetTextSize = surface.GetTextSize

	local Cache = {}

	function CachedTextSize( text, font )

		if ( not font ) then
			return SurfaceGetTextSize( text )
		end

		local FontSection = Cache[font]

		if ( not FontSection ) then

			FontSection = {}
			Cache[font] = FontSection

		end

		local textsize_t = FontSection[text]

		if ( textsize_t ) then
			return textsize_t[1], textsize_t[2]
		end

		if ( strfind( text, '\t' ) ) then

			-- surface.GetTextSize doesn't take into account tabs
			-- and some fonts lack configuration regarding the tab character
			local tabSize = 8
			text = strgsub( text, '\t', strrep( ' ', tabSize ) )

		end

		local w, h = SurfaceGetTextSize( text )
		FontSection[text] = { w; h }

		return w, h

	end

	timer.Create( 'nonsrgbdraw_cachedtextsizegc', 10, 0, function()

		Cache = {}

	end )

end

nonsrgbdraw.GetTextSize = CachedTextSize

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: cam.Start2D but the render context is upvalued
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local CamStart2D; do

	local CamStart = cam.Start

	local g_2DRenderContext = { type = '2D' }

	function CamStart2D()

		CamStart( g_2DRenderContext )

	end

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Rect
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function Rect( x, y, w, h, color )

	if ( color ) then

		if ( color.a == 0 ) then
			return
		end

		SurfaceSetDrawColor( color.r, color.g, color.b, color.a )

	end

	SurfaceSetMaterial( MAT_SMALL )
	SurfaceDrawTexturedRect( x, y, w, h )

end

nonsrgbdraw.Rect = Rect

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	OutlinedRect
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function OutlinedRect( x, y, w, h, color, thickness )

	if ( color ) then

		if ( color.a == 0 ) then
			return
		end

		SurfaceSetDrawColor( color.r, color.g, color.b, color.a )

	end

	SurfaceSetMaterial( MAT_SMALL )

	local t = mathmin( thickness or 1, mathfloor( w * 0.5 ), mathfloor( h * 0.5 ) )

	SurfaceDrawTexturedRect( x, y, t, h ) -- left
	SurfaceDrawTexturedRect( x + t, y, w - t, t ) -- top
	SurfaceDrawTexturedRect( x + w - t, y + t, t, h - t * 2 ) -- right
	SurfaceDrawTexturedRect( x + t, y + h - t, w - t, t ) -- bottom

end

nonsrgbdraw.OutlinedRect = OutlinedRect

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	RoundedBoxEx
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local RoundedBoxEx; do

	local mat_corner8	= CreateNonSRGBMaterial( 'corner8', 'gui/corner8' )
	local mat_corner16	= CreateNonSRGBMaterial( 'corner16', 'gui/corner16' )
	local mat_corner32	= CreateNonSRGBMaterial( 'corner32', 'gui/corner32' )
	local mat_corner64	= CreateNonSRGBMaterial( 'corner64', 'gui/corner64' )
	local mat_corner512	= CreateNonSRGBMaterial( 'corner512', 'gui/corner512' )

	function RoundedBoxEx( r, x, y, w, h, color, tl, tr, bl, br )

		if ( color ) then

			if ( color.a == 0 ) then
				return
			end

			SurfaceSetDrawColor( color.r, color.g, color.b, color.a )

		end

		if ( r < 1 ) then
			Rect( x, y, w, h )
			return
		end

		x = mathfloor( x + 0.5 )
		y = mathfloor( y + 0.5 )
		w = mathfloor( w + 0.5 )
		h = mathfloor( h + 0.5 )

		r = mathmin( mathroundtoeven( r ), mathfloor( w * 0.5 ), mathfloor( h * 0.5 ) )

		SurfaceSetMaterial( MAT_SMALL )

		SurfaceDrawTexturedRect( x + r, y, w - r * 2, h )
		SurfaceDrawTexturedRect( x, y + r, r, h - r * 2 )
		SurfaceDrawTexturedRect( x + w - r, y + r, r, h - r * 2 )

		if ( not tl ) then
			SurfaceDrawTexturedRect( x, y, r, r )
		end

		if ( not tr ) then
			SurfaceDrawTexturedRect( x + w - r, y, r, r )
		end

		if ( not bl ) then
			SurfaceDrawTexturedRect( x, y + h - r, r, r )
		end

		if ( not br ) then
			SurfaceDrawTexturedRect( x + w - r, y + h - r, r, r )
		end

		local mat = mat_corner8

		if ( r > 8 ) then mat = mat_corner16 end
		if ( r > 16 ) then mat = mat_corner32 end
		if ( r > 32 ) then mat = mat_corner64 end
		if ( r > 64 ) then mat = mat_corner512 end

		SurfaceSetMaterial( mat )

		if ( tl ) then
			SurfaceDrawTexturedRectUV( x, y, r, r, 0, 0, 1, 1 )
		end

		if ( tr ) then
			SurfaceDrawTexturedRectUV( x + w - r, y, r, r, 1, 0, 0, 1 )
		end

		if ( bl ) then
			SurfaceDrawTexturedRectUV( x, y + h -r, r, r, 0, 1, 1, 0 )
		end

		if ( br ) then
			SurfaceDrawTexturedRectUV( x + w - r, y + h - r, r, r, 1, 1, 0, 0 )
		end

	end

end

nonsrgbdraw.RoundedBoxEx = RoundedBoxEx

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	RoundedBox
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function RoundedBox( r, x, y, w, h, color )

	RoundedBoxEx( r, x, y, w, h, color, true, true, true, true )

end

nonsrgbdraw.RoundedBox = RoundedBox


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Soft shadows for text

	Note: except for SimpleTextOutlined.
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local ALPHA_SHADOW_LAYER1 = 255 * 0.618
local ALPHA_SHADOW_LAYER2 = 255 * 0.618 * 0.618

local RENDER_TEXTSHADOWS = false

function nonsrgbdraw.ApplyTextShadows()

	RENDER_TEXTSHADOWS = true

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	SimpleText
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function SimpleText( text, font, x, y, color, xAlign, yAlign )

	if ( color and color.a == 0 ) then
		return
	end

	do

		text = tostring( text )
		font = font or 'DermaDefault'
		x = x or 0
		y = y or 0
		xAlign = xAlign or TEXT_ALIGN_LEFT
		yAlign = yAlign or TEXT_ALIGN_TOP

	end

	SurfaceSetFont( font )

	RenderPushTarget( RT_BIG )

		RenderClear( 255, 255, 255, 0 )

		CamStart2D()

			SurfaceSetTextPos( 0, 0 )
			SurfaceSetTextColor( 255, 255, 255, 255 )
			SurfaceDrawText( text )

		CamEnd2D()

	RenderPopTarget()

	local w, h = CachedTextSize( text, font )

	do

		if ( xAlign == TEXT_ALIGN_CENTER ) then
			x = x - w * 0.5
		elseif ( xAlign == TEXT_ALIGN_RIGHT ) then
			x = x - w
		end

		if ( yAlign == TEXT_ALIGN_CENTER ) then
			y = y - h * 0.5
		elseif ( yAlign == TEXT_ALIGN_BOTTOM ) then
			y = y - h
		end

	end

	SurfaceSetMaterial( MAT_BIG )

	local u1, v1 = w * SCREEN_W_INV, h * SCREEN_H_INV

	if ( RENDER_TEXTSHADOWS ) then

		SurfaceSetDrawColor( 0, 0, 0, ALPHA_SHADOW_LAYER2 )
		SurfaceDrawTexturedRectUV( x + 2, y + 2, w, h, 0, 0, u1, v1 )

		SurfaceSetDrawColor( 0, 0, 0, ALPHA_SHADOW_LAYER1 )
		SurfaceDrawTexturedRectUV( x + 1, y + 1, w, h, 0, 0, u1, v1 )

	end

	if ( color ) then
		SurfaceSetDrawColor( color.r, color.g, color.b, color.a )
	else
		SurfaceSetDrawColor( 255, 255, 255, 255 )
	end

	SurfaceDrawTexturedRectUV( x, y, w, h, 0, 0, u1, v1 )

	return w, h

end

nonsrgbdraw.SimpleText = SimpleText

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	SimpleTextOutlined
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function SimpleTextOutlined( text, font, x, y, color, xAlign, yAlign, outlineWidth, colorOutline )

	if ( color and color.a == 0 ) then
		return
	end

	do

		text = tostring( text )
		font = font or 'DermaDefault'
		x = x or 0
		y = y or 0
		xAlign = xAlign or TEXT_ALIGN_LEFT
		yAlign = yAlign or TEXT_ALIGN_TOP

	end

	SurfaceSetFont( font )

	RenderPushTarget( RT_BIG )

		RenderClear( 255, 255, 255, 0 )

		CamStart2D()

			SurfaceSetTextPos( 0, 0 )
			SurfaceSetTextColor( 255, 255, 255, 255 )
			SurfaceDrawText( text )

		CamEnd2D()

	RenderPopTarget()

	local w, h = CachedTextSize( text, font )

	do

		if ( xAlign == TEXT_ALIGN_CENTER ) then
			x = x - w * 0.5
		elseif ( xAlign == TEXT_ALIGN_RIGHT ) then
			x = x - w
		end

		if ( yAlign == TEXT_ALIGN_CENTER ) then
			y = y - h * 0.5
		elseif ( yAlign == TEXT_ALIGN_BOTTOM ) then
			y = y - h
		end

	end

	SurfaceSetMaterial( MAT_BIG )

	local u1, v1 = w * SCREEN_W_INV, h * SCREEN_H_INV

	if ( colorOutline ) then
		SurfaceSetDrawColor( colorOutline.r, colorOutline.g, colorOutline.b, colorOutline.a )
	else
		SurfaceSetDrawColor( 255, 255, 255, 255 )
	end

	local steps = ( outlineWidth * 2 ) / 3
	if ( steps < 1 ) then steps = 1 end

	for xOutline = -outlineWidth, outlineWidth, steps do

		for yOutline = -outlineWidth, outlineWidth, steps do
			SurfaceDrawTexturedRectUV( x + xOutline, y + yOutline, w, h, 0, 0, u1, v1 )
		end

	end

	if ( color ) then
		SurfaceSetDrawColor( color.r, color.g, color.b, color.a )
	else
		SurfaceSetDrawColor( 255, 255, 255, 255 )
	end

	SurfaceDrawTexturedRectUV( x, y, w, h, 0, 0, u1, v1 )

	return w, h

end

nonsrgbdraw.SimpleTextOutlined = SimpleTextOutlined

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Text
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local Text; do

	local strgmatch = string.gmatch

	function Text( text, font, x, y, color, xAlign )

		if ( color and color.a == 0 ) then
			return
		end

		local bCenterAligned = xAlign == TEXT_ALIGN_CENTER
		local bRightAligned = xAlign == TEXT_ALIGN_RIGHT

		do

			text = tostring( text )
			font = font or 'DermaDefault'
			x = x or 0
			y = y or 0

			if ( strfind( text, '\t' ) ) then

				-- surface.GetTextSize doesn't take into account tabs
				-- and some fonts lack configuration regarding the tab character
				local tabSize = 8
				text = strgsub( text, '\t', strrep( ' ', tabSize ) )

			end

		end

		local w = CachedTextSize( text, font )
		local h = 0

		local xOffset = 0
		local yOffset = 0

		SurfaceSetFont( font )

		local _, lineHeight = CachedTextSize( ' ', font )

		RenderPushTarget( RT_BIG )

			RenderClear( 255, 255, 255, 0 )

			CamStart2D()

				SurfaceSetTextColor( 255, 255, 255, 255 )

				for line in strgmatch( text, '[^\n]*' ) do

					if ( line ~= '' ) then

						local lineW

						if ( bCenterAligned ) then

							lineW = CachedTextSize( line, font )
							xOffset = w * 0.5 - lineW * 0.5

						elseif ( bRightAligned ) then

							lineW = CachedTextSize( line, font )
							xOffset = w - lineW

						end

						SurfaceSetTextPos( xOffset, yOffset )
						SurfaceDrawText( line )

					else
						yOffset = yOffset + lineHeight
					end

					h = h + lineHeight
					xOffset = 0

				end

			CamEnd2D()

		RenderPopTarget()

		SurfaceSetMaterial( MAT_BIG )

		do

			if ( bCenterAligned ) then
				x = x - w * 0.5
			elseif ( bRightAligned ) then
				x = x - w
			end

		end

		local u1, v1 = w * SCREEN_W_INV, h * SCREEN_H_INV

		if ( RENDER_TEXTSHADOWS ) then

			SurfaceSetDrawColor( 0, 0, 0, ALPHA_SHADOW_LAYER2 )
			SurfaceDrawTexturedRectUV( x + 2, y + 2, w, h, 0, 0, u1, v1 )

			SurfaceSetDrawColor( 0, 0, 0, ALPHA_SHADOW_LAYER1 )
			SurfaceDrawTexturedRectUV( x + 1, y + 1, w, h, 0, 0, u1, v1 )

		end

		if ( color ) then
			SurfaceSetDrawColor( color.r, color.g, color.b, color.a )
		else
			SurfaceSetDrawColor( 255, 255, 255, 255 )
		end

		SurfaceDrawTexturedRectUV( x, y, w, h, 0, 0, u1, v1 )

		return w, h

	end

end

nonsrgbdraw.Text = Text
