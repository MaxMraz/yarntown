/*
 * Copyright (C) 2018 Solarus - http://www.solarus-games.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Originally from a repository of BSNES shaders.
// Modified by slime73 for use with love2d and mari0.
// Adapted for Solarus by Vlag and Christopho.

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
precision mediump float;
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform sampler2D sol_texture;
COMPAT_VARYING vec2 sol_vtex_coord;
COMPAT_VARYING vec4 sol_vcolor;

uniform vec2 sol_input_size;
uniform vec2 sol_output_size;
vec2 sol_texture_size = sol_input_size;

const float mx = 0.325;      // start smoothing wt.
const float k = -0.250;      // wt. decrease factor
const float max_w = 0.25;    // max filter weight
const float min_w =-0.05;    // min filter weight
const float lum_add = 0.25;  // effects smoothing

vec2 texcoord = sol_vtex_coord;

void main() {
    float x = 0.5 / sol_texture_size.x;
    float y = 0.5 / sol_texture_size.y;
    vec2 dg1 = vec2( x, y);
    vec2 dg2 = vec2(-x, y);
    vec2 dx = vec2(x, 0.0);
    vec2 dy = vec2(0.0, y);
 
    vec4 texcolor = COMPAT_TEXTURE(sol_texture, texcoord);

    vec3 c00 = COMPAT_TEXTURE(sol_texture, texcoord - dg1).xyz;
    vec3 c10 = COMPAT_TEXTURE(sol_texture, texcoord - dy).xyz;
    vec3 c20 = COMPAT_TEXTURE(sol_texture, texcoord - dg2).xyz;
    vec3 c01 = COMPAT_TEXTURE(sol_texture, texcoord - dx).xyz;
    vec3 c11 = texcolor.xyz;
    vec3 c21 = COMPAT_TEXTURE(sol_texture, texcoord + dx).xyz;
    vec3 c02 = COMPAT_TEXTURE(sol_texture, texcoord + dg2).xyz;
    vec3 c12 = COMPAT_TEXTURE(sol_texture, texcoord + dy).xyz;
    vec3 c22 = COMPAT_TEXTURE(sol_texture, texcoord + dg1).xyz;
    vec3 dt = vec3(1.0, 1.0, 1.0);

    float md1 = dot(abs(c00 - c22), dt);
    float md2 = dot(abs(c02 - c20), dt);

    float w1 = dot(abs(c22 - c11), dt) * md2;
    float w2 = dot(abs(c02 - c11), dt) * md1;
    float w3 = dot(abs(c00 - c11), dt) * md2;
    float w4 = dot(abs(c20 - c11), dt) * md1;

    float t1 = w1 + w3;
    float t2 = w2 + w4;
    float ww = max(t1, t2) + 0.0001;

    c11 = (w1 * c00 + w2 * c20 + w3 * c22 + w4 * c02 + ww * c11) / (t1 + t2 + ww);

    float lc1 = k / (0.12 * dot(c10 + c12 + c11, dt) + lum_add);
    float lc2 = k / (0.12 * dot(c01 + c21 + c11, dt) + lum_add);

    w1 = clamp(lc1 * dot(abs(c11 - c10), dt) + mx, min_w, max_w);
    w2 = clamp(lc2 * dot(abs(c11 - c21), dt) + mx, min_w, max_w);
    w3 = clamp(lc1 * dot(abs(c11 - c12), dt) + mx, min_w, max_w);
    w4 = clamp(lc2 * dot(abs(c11 - c01), dt) + mx, min_w, max_w);

    FragColor = vec4(w1 * c10 + w2 * c21 + w3 * c12 + w4 * c01 + (1.0 - w1 - w2 - w3 - w4) * c11, 1.0);
}