shader_type canvas_item;

// -------------------------------------------------------------------------
// Uniforms
// All of these are driveable at runtime by the Sigil, Chromatic Dissonance /
// Resonance, and prestige systems. The defaults produce the idle breathing look.
// -------------------------------------------------------------------------

// Speed of the breathing pulse cycle in radians per second.
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;

// Peak-to-trough brightness swing of the pulse.
// 0.0 = completely static, 0.5 = large dramatic throb.
uniform float pulse_amplitude : hint_range(0.0, 0.5) = 0.12;

// Overall glow multiplier.
// Sits at 1.0 at rest. Driven toward 2-3 when a Sigil activates or
// Chromatic Resonance fires, returning to 1.0 as the event fades.
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;

// Color saturation multiplier.
// 1.0 = natural color. Chromatic Dissonance pushes this down toward grey.
// Chromatic Resonance pushes it up toward 2.0 for vivid oversaturation.
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

// Circumradius of this piece in local pixels.
// Must be kept in sync with SIZE_RADII[size_tier] from MandalaPiece.gd so
// the inner glow gradient scales correctly when piece size changes.
uniform float shape_radius : hint_range(1.0, 200.0) = 60.0;

// How much brighter the polygon center is vs its edge.
// Creates a "lit from within" feel. Increase for more pronounced inner glow.
uniform float inner_glow_strength : hint_range(0.0, 1.0) = 0.35;


// -------------------------------------------------------------------------
// Varyings
// -------------------------------------------------------------------------

// Local-space position of each vertex, interpolated across fragments.
// Lets the fragment shader compute each pixel's distance from the polygon
// center without needing a texture or screen-space tricks.
varying vec2 local_position;


// -------------------------------------------------------------------------
// Vertex
// -------------------------------------------------------------------------

void vertex() {
	local_position = VERTEX;
}


// -------------------------------------------------------------------------
// Fragment
// -------------------------------------------------------------------------

void fragment() {
	vec4 base_color = COLOR;

	// --- Saturation -------------------------------------------------------
	// Blend between a luminance-preserving greyscale and the full-color value.
	// Luminance weights follow the standard Rec. 601 coefficients.
	float luminance = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3  saturated = mix(vec3(luminance), base_color.rgb, saturation);

	// --- Inner glow gradient ----------------------------------------------
	// Brightest at the polygon center, tapering to full base color at the edge.
	// dist_normalised = 0.0 at center, 1.0 at the circumradius.
	float dist_normalised   = clamp(length(local_position) / shape_radius, 0.0, 1.0);
	float inner_glow_factor = mix(1.0 + inner_glow_strength, 1.0, dist_normalised);

	// --- Breathing pulse --------------------------------------------------
	// A slow sine wave that gently brightens and dims the entire piece.
	// Pieces on different arms will share the same TIME so they pulse in sync,
	// which reinforces the mandala's rotational symmetry visually.
	float pulse_factor = 1.0 + pulse_amplitude * sin(TIME * pulse_speed);

	// --- Combine ----------------------------------------------------------
	vec3 final_color = saturated * inner_glow_factor * pulse_factor * glow_intensity;

	ALBEDO = final_color;
	ALPHA  = base_color.a;
}
