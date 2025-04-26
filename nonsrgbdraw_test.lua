local function nonsrgbdraw_test_f()

	if ( IsValid( ColorTest ) ) then
		return
	end

	local g_ColorTested = Color( math.Rand( 0, 255 ), math.Rand( 0, 255 ), math.Rand( 0, 255 ) )

	local g_Font = 'DermaLarge'
	local g_Text = 'Lorem ipsum dolor sit amet'

	local g_bObtainColors = true

	local RT_OBTAINCOLORS = GetRenderTargetEx(

		'obtaincolors',
		2, 1,
		RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE,
		1 + 256 + 512, 0,
		IMAGE_FORMAT_BGRA8888

	)

	local r1, g1, b1, a1 = 0, 0, 0, 255
	local r2, g2, b2, a2 = 0, 0, 0, 255

	local function fnObtainColors()

		render.PushRenderTarget( RT_OBTAINCOLORS )

			render.Clear( 0, 0, 0, 0 )

			cam.Start2D()

				surface.SetDrawColor( g_ColorTested )

				surface.DrawRect( 0, 0, 1, 1 )
				nonsrgbdraw.Rect( 1, 0, 1, 1 )

			cam.End2D()

			render.CapturePixels()
			r1, g1, b1, a1 = render.ReadPixel( 0, 0 )
			r2, g2, b2, a2 = render.ReadPixel( 1, 0 )

		render.PopRenderTarget()

	end

	if ( ColorTest ) then

		ColorTest:Remove()
		ColorTest = nil

	end

	--
	-- Main frame
	--
	ColorTest = vgui.Create( 'DFrame' )
	ColorTest:SetTitle( 'Color Test — Default/non-sRGB' )
	ColorTest:SetSize( 960, 480 )
	ColorTest:SetSizable( true )
	ColorTest:Center()
	ColorTest:MakePopup()

	function ColorTest:Paint( w, h )

		nonsrgbdraw.OutlinedRect( 0, 0, w, h, color_white )

	end

	--
	-- Color choice
	--
	local Mixer = ColorTest:Add( 'DColorMixer' )
	Mixer:Dock( LEFT )
	Mixer:SetColor( g_ColorTested )

	function Mixer:ValueChanged( col )

		g_ColorTested = col
		g_bObtainColors = true

	end

	local Randomize = Mixer:Add( 'DButton' )
	Randomize:SetZPos( -1 )
	Randomize:Dock( BOTTOM )
	Randomize:DockMargin( 0, 2, 0, 0 )
	Randomize:SetText( 'Randomize' )
	Randomize.DoClick = function()

		Mixer:SetColor( Color( math.Rand( 0, 255 ), math.Rand( 0, 255 ), math.Rand( 0, 255 ) ) )

	end

	--
	-- Testing polygon
	--
	local Polygon = ColorTest:Add( 'EditablePanel' )
	Polygon:Dock( FILL )
	Polygon:DockMargin( 4, 0, 0, 0 )

	--
	-- Texts
	--
	local TextsCanvas = Polygon:Add( 'EditablePanel' )
	TextsCanvas:SetZPos( -1 )
	TextsCanvas:Dock( TOP )
	TextsCanvas:DockMargin( 0, 0, 0, 4 )

	local TextChoice = TextsCanvas:Add( 'DTextEntry' )
	TextChoice:Dock( TOP )
	TextChoice:DockMargin( 0, 0, 0, 2 )
	TextChoice:SetUpdateOnType( true )
	TextChoice:SetPlaceholderText( 'Lorem ipsum dolor sit amet.' )

	local FontChoice = TextsCanvas:Add( 'DTextEntry' )
	FontChoice:SetZPos( 1 )
	FontChoice:Dock( TOP )
	FontChoice:SetPlaceholderText( 'DermaLarge (Press ENTER to change the font)' )

	local TextDefault = TextsCanvas:Add( 'EditablePanel' )
	TextDefault:SetZPos( 2 )
	TextDefault:Dock( TOP )

	function TextDefault:Paint()

		draw.SimpleText( g_Text, g_Font, 0, 0, g_ColorTested )

	end

	local TextNonSRGB = TextsCanvas:Add( 'EditablePanel' )
	TextNonSRGB:SetZPos( 3 )
	TextNonSRGB:Dock( TOP )

	function TextNonSRGB:Paint()

		nonsrgbdraw.SimpleText( g_Text .. ' (non-sRGB)', g_Font, 0, 0, g_ColorTested )

	end

	local function fnLayoutTexts()

		surface.SetFont( g_Font )
		local _, h = nonsrgbdraw.GetTextSize( g_Text )

		TextDefault:SetTall( h * 1.1 )
		TextNonSRGB:SetTall( h * 1.1 )

		TextsCanvas:InvalidateLayout( true )
		TextsCanvas:SizeToChildren( false, true )

	end

	function TextChoice:OnValueChange( text )

		g_Text = text

		fnLayoutTexts()

	end

	function FontChoice:OnEnter( font )

		g_Font = font

		fnLayoutTexts()

	end

	fnLayoutTexts()

	--
	-- Colors set against each other
	--
	local Comparison = Polygon:Add( 'EditablePanel' )
	Comparison:Dock( FILL )

	function Comparison:Paint( w, h )

		local w_half, h_half = w * 0.5, h * 0.5

		--
		-- Draw comparison
		--
		surface.SetDrawColor( g_ColorTested )

		surface.DrawRect( 0, 0, w_half, h )
		nonsrgbdraw.Rect( w_half, 0, w_half, h )

		--
		-- Obtain colors
		--
		if ( g_bObtainColors ) then

			fnObtainColors()
			g_bObtainColors = false

		end

		--
		-- Info
		--
		local colText = g_ColorTested:GetLightness() >= 0.67 and color_black or color_white

		draw.DrawText(

			Format( 'Default\n%i, %i, %i, %i', r1, g1, b1, a1 ),
			'DermaDefault',

			w_half * 0.5,
			h_half,

			colText,

			TEXT_ALIGN_CENTER

		)

		draw.DrawText(

			Format( 'non-sRGB\n%i, %i, %i, %i', r2, g2, b2, a2 ),
			'DermaDefault',

			w - w_half * 0.5,
			h_half,

			colText,

			TEXT_ALIGN_CENTER

		)

	end


	--
	-- Rounded Boxes Frame
	--
	RoundedBoxesTest = vgui.Create( 'DFrame' )
	RoundedBoxesTest:SetTitle( 'Rounded Boxes (Default/non-sRGB)' )
	RoundedBoxesTest:SetSize( 480, 240 )
	RoundedBoxesTest:SetSizable( true )
	RoundedBoxesTest:MoveBelow( ColorTest, 5 )
	RoundedBoxesTest:CenterHorizontal()

	function ColorTest:OnRemove()

		RoundedBoxesTest:Remove()
		RoundedBoxesTest = nil

	end

	function RoundedBoxesTest:Paint( w, h )

		nonsrgbdraw.OutlinedRect( 0, 0, w, h, color_white )

	end

	local Radius = RoundedBoxesTest:Add( 'DNumSlider' )
	Radius:Dock( TOP )
	Radius:SetText( 'Radius' )
	Radius:SetMin( 0 )
	Radius:SetMax( 512 )
	Radius:SetDecimals( 1 )
	Radius:SetValue( 8 )

	local RoundedBoxes = RoundedBoxesTest:Add( 'EditablePanel' )
	RoundedBoxes:Dock( FILL )

	function RoundedBoxes:Paint( w, h )

		nonsrgbdraw.OutlinedRect( 0, 0, w, h, color_white )

		local r = Radius:GetValue()

		local size = math.min( w - 5, h - 5 )

		draw.RoundedBoxEx(

			r,

			w * 0.25 - size * 0.5,
			h * 0.5 - size * 0.5,

			size,
			size,

			g_ColorTested,

			false, true, true, false

		)

		nonsrgbdraw.RoundedBoxEx(

			r,

			w * 0.75 - size * 0.5,
			h * 0.5 - size * 0.5,

			size,
			size,

			g_ColorTested,

			false, true, true, false

		)

	end

end

concommand.Add( 'nonsrgbdraw_test', nonsrgbdraw_test_f )
