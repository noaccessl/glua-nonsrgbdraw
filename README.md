# glua-nonsrgbdraw
 A non-sRGB draw library for Garry's Mod.

### Functions
 * `Rect`
 * `OutlinedRect`
 * `RoundedBox`
 * `RoundedBoxEx`
	* Peculiarity: `radius` is rounded to the closest even number
 * `SimpleText`
 * `SimpleTextOutlined`
 * `Text` _(analogous to draw.DrawText)_

 **P.S.** The use of them is as with the default ones.

 * `ApplyTextShadows`
	* Internally marks the next text to be rendered with soft shadows

### Features
 Slightly more precise rendering compared to the default **`surface`** & **`draw`** libraries. _(regarding shapes)_

 **`nonsrgbdraw.Text`** works slightly better/more properly than **`draw.DrawText`**

### Motive
 Under the hood, **Source Engine** by default allows the internal shader system to apply gamma correction unto the in-game/GUI textures, materials.

 Gamma correction in and of itself isn't evil.
 </br>
 It simply results in incongruity between the color intended and the color rendered. **(it also applies to alpha value)**
 </br>
 Related topic: [garrysmod-issues/2807](https://github.com/Facepunch/garrysmod-issues/issues/2807)

 And we can turn this off on materials with three particular shaders: `UnlitGeneric`, `VertexLitGeneric`, `screenspace_general`.
 </br>
 References:
 </br>
 [source-sdk-2013/materialsystem/stdshaders/unlitgeneric_dx9.cpp#L74-L75](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/materialsystem/stdshaders/unlitgeneric_dx9.cpp#L74-L75)
 </br>
 [source-sdk-2013/materialsystem/stdshaders/vertexlitgeneric_dx9.cpp#L133](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/materialsystem/stdshaders/vertexlitgeneric_dx9.cpp#L133)
 </br>
 [source-sdk-2013/materialsystem/stdshaders/screenspace_general.cpp#L39-L43](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/materialsystem/stdshaders/screenspace_general.cpp#L39-L43)

 So, I've decided to assemble a library for this. It's truthful when the intended color is rendered.
 </br>
 Along with this, an obsession with pixels isn't the end goal.

### Demo
 Use [nonsrgbdraw_test.lua](./nonsrgbdraw_test.lua)
