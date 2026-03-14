**SIGIL ENGINE**

Game Design Document

v0.1 --- Game Jam Edition

**1. Overview**

Sigil Engine is a meditative incremental game about rebuilding a lost
cosmic pattern. The player takes the role of an Astral Scholar
attempting to channel enough Flux energy to trigger The Convergence ---
a reconstruction of a perfect Mandala that existed at the birth of the
universe.

The core loop involves placing geometric shapes onto a living Mandala
that grows with rotational symmetry. Shapes generate resources, combine
into Sigils with special effects, and can be colored to alter their
power. Each completed Mandala is archived and continues generating
resources passively, while the Scholar begins a new, more powerful one.

  ----------------------------------- -----------------------------------
  **Attribute**                       **Detail**

  Engine                              Godot 4.6

  Language                            GDScript

  Genre                               Incremental / Idle

  Target Platform                     PC (Windows / Mac / Linux)

  Art Style                           Geometric shapes, shaders, no
                                      textures

  Jam Time Budget                     1 month (evenings + weekends)
  ----------------------------------- -----------------------------------

**2. Core Fantasy & Pillars**

You are not casting spells. You are building the machine that casts the
spell.

**Design Pillars**

-   The Mandala is the Machine --- every shape placed is both visual art
    and functional game logic. Beauty and mechanics are inseparable.

-   Discovery over Instruction --- Sigils are never explained upfront.
    You experiment, observe, and record findings in your Tome.

-   Symmetry as Satisfaction --- placing one shape places many. Every
    action has immediate visual payoff.

-   Meditative Pacing --- the game breathes. It is never urgent. You
    tend something.

-   Legacy Matters --- archived Mandalas persist visually and
    mechanically. Your history is always visible.

**3. Screen Layout**

  ---------------------- ------------------------------------------------
  **Region**             **Contents**

  Left / Center (main)   Mandala viewport --- active mandala centered,
                         starfield background, archived mandalas glowing
                         behind

  Right panel            Shop, resource counters, shape/color selectors,
                         Tome button

  Arm 0                  The canonical placement arm --- player only
                         interacts here; mirrored arms are display-only

  Camera                 Right-click to pan, scroll wheel to zoom
                         (0.3x--3.0x), Home button to re-center
  ---------------------- ------------------------------------------------

The starfield background consists of 2--3 parallax layers of drifting
stars, providing cosmic depth while the Mandala is small early game. A
subtle mouse-parallax tilt effect adds life without distraction.

**4. The Symmetry System**

The Mandala begins with a single center shape chosen at the start of
each run. This center shape determines the symmetry order for the entire
Mandala --- all placements replicate across that many arms
simultaneously.

The player always places shapes on Arm 0 only. The engine automatically
mirrors the placement across all other arms. Mirrored arms are purely
visual --- no raycasting, hit detection, or Sigil checking occurs on
them.

  ---------------- -------------- --------------- -------------------------
  **Center Shape** **Symmetry**   **Cost          **Character**
                                  Multiplier**    

  Triangle         3-fold         3x per          Fast early growth, cheap,
                                  placement       beginner-friendly

  Square           4-fold         4x per          Balanced, grid-like
                                  placement       structure

  Pentagon         5-fold         5x per          Expensive, exotic,
                                  placement       beautiful --- challenge
                                                  run

  Hexagon          6-fold         6x per          Late game unlock, dense,
                                  placement       very costly
  ---------------- -------------- --------------- -------------------------

Symmetry replication math: for each arm index i (0 to N-1), the mirrored
position is the Arm 0 position rotated by (2 \* PI / N) \* i around the
Mandala center. Rotation is handled the same way.

**Growth Model**

The Mandala grows organically outward from the center based on player
choices. Each placed shape exposes its outer edges as open placement
slots. The shape of the available frontier changes with every placement,
creating an evolving puzzle of opportunities.

-   Edges shared between two placed shapes are closed --- never
    available for placement.

-   Only outer edges (touching empty space) are open.

-   The Mandala has no fixed rings --- it grows in whatever direction
    the player chooses.

**5. Shapes**

**Shape Properties**

All shapes use the same side length --- the difference between them is
the number of sides. Sizes are multiplicative (Small = 0.7x, Normal =
1.0x, Large = 2.0x, Vast = 3.0x side length) and affect both visual
footprint and adjacency radius for Sigil detection.

  ------------- ----------- ----------- ------------------------------------
  **Shape**     **Sides**   **Base      **Notes**
                            Role**      

  Triangle      3           Generator   Produces Aether. Starter shape,
                                        available from run start.

  Square        4           Converter   Transforms Aether into Flux.
                                        Unlocked via Resonance.

  Pentagon      5           Catalyst    Triggers special Sigil reactions.
                                        Oscillates visually.

  Hexagon       6           Amplifier   Boosts adjacent node output.
                                        Radiates connection lines.

  Octagon       8           Exotic      Late-game unlock. Rare, powerful,
                                        complex Sigil anchor.
  ------------- ----------- ----------- ------------------------------------

**Size Tiers**

  ------------- --------------- --------------- ---------------------------
  **Size**      **Cost          **Output        **Notes**
                Multiplier**    Multiplier**    

  Small         0.7x            0.8x            Dense packing. Tight visual
                                                clusters.

  Normal        1.0x            1.0x            Default. Standard adjacency
                                                radius.

  Large         2.5x            2.0x            Dramatic visual. Expanded
                                                adjacency.

  Vast          8.0x            4.5x            One per Mandala
                                                recommended. Enormous
                                                investment and payoff.
  ------------- --------------- --------------- ---------------------------

**6. Colors & Chromatic Dissonance**

Color is a multiplier layer applied on top of a shape\'s base output.
Colors must be purchased with Resonance (the persistent currency) and
are available in all future runs once unlocked.

  ------------ -------------- --------------- ------------------------------
  **Color**    **Output       **Relative      **Unlock Cost (Resonance)**
               Multiplier**   Cost**          

  Grey         1.0x           Base            Free --- available from start

  Blue         1.2x           +40%            50 Resonance

  Red          1.5x           +100%           200 Resonance

  Purple       1.6x           +130%           500 Resonance (branch unlock)

  Gold         1.8x           +200%           800 Resonance
  ------------ -------------- --------------- ------------------------------

**Chromatic Dissonance --- The Anti-Stacking Rule**

Without a penalty, players would always choose Gold. Chromatic
Dissonance prevents color stacking from being trivially optimal:

-   Each shape checks all directly adjacent neighbors at placement and
    on each calculation tick.

-   For every neighbor sharing the same color: subtract 0.15x from that
    shape\'s effective multiplier.

-   Gold with 2 Gold neighbors = 1.8 - 0.30 = 1.5x --- equivalent to
    Red, at twice the cost.

-   Gold with 3 Gold neighbors = 1.8 - 0.45 = 1.35x --- worse than Red.

**Chromatic Resonance --- The Diversity Bonus**

Actively rewarding color variety: if all of a shape\'s direct neighbors
are different colors from each other (and from the shape itself), that
shape gains a +0.3x bonus. This encourages colorful, visually rich
Mandalas and gives an active optimization target beyond just avoiding
same-color adjacency.

**7. Resource Economy**

  -------------- --------------- -------------------- ---------------------
  **Resource**   **Resets on     **Primary Source**   **Primary Sink**
                 Prestige**                           

  Aether         Yes             Triangles and        Purchasing shapes for
                                 Generator Sigils     current Mandala

  Flux           No (archived    Converter shapes,    The Convergence
                 Mandalas keep   Sigils, archived     threshold --- the win
                 generating)     Mandalas             condition

  Resonance      Never           Discovering new      Persistent unlock
                                 Sigils, Scholar Rank shop --- shapes,
                                 milestones           colors, sizes
  -------------- --------------- -------------------- ---------------------

Aether is the moment-to-moment currency. Flux is the long-term progress
meter. Resonance is the permanent meta-progression currency. Each has a
clear role with no redundancy.

**Resource Flow Diagram**

> Shapes generate Aether → Aether buys more shapes → Sigils
> convert/amplify Aether into Flux
>
> Flux accumulates across all Mandalas → Reaches Convergence threshold →
> Win condition
>
> Sigil discovery rewards Resonance → Resonance unlocks
> shapes/colors/sizes permanently

**8. The Sigil System**

Sigils are emergent effects that activate when specific combinations of
shapes (and optionally colors) are placed adjacent to each other. They
are never explained to the player --- discovery is core to the
experience.

**Detection**

-   After every shape placement, run a neighbor scan on all newly placed
    shapes (Arm 0 only --- mirror arms inherit the same Sigil state).

-   Compare the local neighborhood pattern against the Sigil registry.

-   If a match is found and it is not yet active, activate the Sigil,
    award Resonance, and record it in the Tome.

-   Sigils remain active as long as their constituent shapes are present
    (they cannot be removed once placed).

**Multi-Sigil Pieces --- Shared Membership**

A single shape can participate in more than one Sigil simultaneously.
Bonuses stack with diminishing returns:

-   First Sigil membership: 100% of Sigil effect.

-   Second Sigil membership: 75% of Sigil effect.

-   Third Sigil membership: 50% of Sigil effect.

-   Further memberships: 25% each.

Certain Sigils have the Intersection trait built into their flavor ---
they explicitly grow stronger when their pieces are shared with other
Sigils, ignoring the diminishing returns penalty.

**Visual Feedback**

-   Dormant shapes: muted colors, slow individual pulse.

-   Active Sigil shapes: saturated vivid colors, glowing edges
    connecting Sigil members, synchronized pulse rhythm shared across
    the whole Sigil cluster.

-   Sparkle hint system: on open edges in Arm 0, if placing the
    currently-selected shape there would complete a known
    (Tome-recorded) Sigil, a sparkle particle effect appears on that
    edge. Unknown Sigils produce no hints.

**Sigil Categories**

  --------------- ---------------------- ---------------------------------
  **Category**    **Trigger Condition**  **Effect Type**

  Shape Sigil     Specific polygon       Flat resource generators or
                  combination, color     output multipliers
                  irrelevant             

  Color Sigil     Specific color         New resource generation, discount
                  pattern, shape         effects
                  irrelevant             

  Compound Sigil  Specific shape AND     Rare, powerful, unique effects.
                  color combination      Rarest discoveries.
  --------------- ---------------------- ---------------------------------

**Example Sigils (Design Reference --- Tuning TBD)**

  ------------- ---------------------- ----------------------------------
  **Name**      **Pattern**            **Effect**

  Crucible      Square surrounded by   +1 Aether/sec flat generator
                Triangles              

  Lens          Triangle surrounded by 1.5x multiplier to cluster output
                Squares                

  Star Sigil    Six Triangles around a Unlocks Flux conversion for this
                Hexagon                Mandala

  Ember Arc     Three Red Triangles in Generates a trickle of Resonance
                a chain                passively

  Crown         Gold shape touching 3+ Doubles the Gold shape\'s output
                different-color        
                neighbors              

  Frost Ring    Alternating Blue/Grey  Next 5 purchases cost 30% less
                ring around any shape  Aether

  Stormheart    Red Triangle           Compound --- rare, large Flux
                surrounded by Blue     multiplier
                Squares                

  The Aureole   Gold Hexagon, complete Compound --- candidate for
                ring of any shapes     Convergence gate
                around it              
  ------------- ---------------------- ----------------------------------

Target: 15--20 discoverable Sigils total for jam scope.

**9. The Tome --- Astral Scholar\'s Journal**

The Tome is the player\'s permanent research journal. It persists across
all prestiges and runs. It is the physical manifestation of scholar
progression.

**Discovered Sigils Section**

-   Each discovered Sigil has a full entry: illustrated pattern diagram,
    name, flavor text, effect description.

-   Once recorded, the sparkle hint system activates for that Sigil in
    all future runs.

**Unknown Sigils Section**

-   Undiscovered Sigils appear as silhouettes or obscured entries with a
    \'???\' name.

-   The player can see how many remain but not what they are.

-   Completing the Tome (all Sigils discovered) is a secondary
    achievement goal.

**10. Prestige --- The Mandala Archive**

Prestige is framed as archiving, not resetting. The player chooses to
Archive their current Mandala when production has plateaued and they are
ready to begin a new one.

**What Happens on Archive**

-   The current Mandala freezes in place and moves to the background. It
    continues generating Flux passively at its peak rate forever.

-   A new Mandala begins at the center of the screen. The archived
    Mandala glows softly behind it.

-   After several prestiges, the background is populated with a
    constellation of glowing geometric artifacts --- all the Scholar\'s
    previous work, still alive.

**Persistent Carries**

  ----------------------------------- -----------------------------------
  **Carries Forward**                 **Resets**

  The Tome --- all discovered Sigils  Active Mandala structure
  and hints                           

  All unlocked colors, shapes, sizes  Current Aether stockpile

  Archived Mandalas and their Flux    Shop purchases for current Mandala
  generation                          

  Resonance (persistent currency)     

  Scholar Rank and its passive        
  bonuses                             
  ----------------------------------- -----------------------------------

**Expected Progression Curve**

  ----------- --------------- --------------- ------------------------------
  **Mandala   **Peak          **Player        **Character**
  \#**        Flux/sec**      Knowledge**     

  1           \~10            Learning basics Slow, exploratory. First Sigil
                                              discoveries.

  2           \~80            Knows 3--5      Faster start. Tome hints help
                              Sigils          early.

  3           \~500           Knows 8--10     Strategic placement emerging.
                              Sigils          

  5+          Thousands       Near-complete   Optimized builds, background
                              Tome            full of archived Mandalas.
  ----------- --------------- --------------- ------------------------------

**11. Win Condition --- The Convergence**

The Scholar is attempting to reconstruct the Ur-Mandala --- a perfect
geometric pattern that existed at the birth of the universe and was
shattered. Each Mandala built is an attempt to approximate it. Flux
represents how closely the Scholar\'s collected works resonate with the
original.

When the total accumulated Flux across all archived and active Mandalas
crosses the Convergence Threshold, the endgame sequence triggers:

-   All archived Mandalas slowly drift toward the center of the screen.

-   They attempt to merge --- overlapping, aligning, finding resonance
    with each other.

-   The result is either a perfect unified pattern (if the player has
    completed the Tome) or a beautifully imperfect approximation.

-   A final screen shows the Scholar\'s completed Tome alongside their
    merged Mandala collection.

The Convergence Threshold is a design tuning value --- set it so a
dedicated player reaches it across 5--8 prestige cycles.

**12. Persistent Unlock Shop**

The unlock shop is accessible at all times via the UI panel. It is
purchased with Resonance (never resets). Unlocks are available from the
very next run after purchase.

**Shape Unlock Tree**

  ------------------ --------------- -------------------------------------
  **Shape**          **Cost          **Prerequisites**
                     (Resonance)**   

  Triangle           Free            Always available

  Square             100             None

  Pentagon           400             Square unlocked

  Hexagon            600             Pentagon unlocked

  Octagon            1500            Hexagon unlocked, 10+ Sigils
                                     discovered
  ------------------ --------------- -------------------------------------

**Color Unlock Tree**

  ------------------ --------------- -------------------------------------
  **Color**          **Cost          **Notes**
                     (Resonance)**   

  Grey               Free            Default

  Blue               50              

  Red                200             

  Purple             500             Branch from Red --- alternate path to
                                     Gold

  Gold               800             Requires Red or Purple
  ------------------ --------------- -------------------------------------

**Size Unlock Tree**

  ------------------ --------------- -------------------------------------
  **Size**           **Cost          **Notes**
                     (Resonance)**   

  Normal             Free            Default

  Small              75              

  Large              300             

  Vast               1200            Requires Large
  ------------------ --------------- -------------------------------------

**13. Development Build Phases**

**Phase 1 --- The Living Mandala (Week 1)**

Goal: A mandala you can build that feels alive. No economy yet.

-   Render Triangle and Square using Polygon2D

-   Symmetry replication math (3-fold for Triangle center)

-   Open edge detection on Arm 0 only

-   Click edge to place --- mirrors automatically

-   Shape selector (Triangle / Square)

-   Color selector (Grey / Blue)

-   Idle pulse and glow shader animations

-   Parallax starfield background

-   Camera pan (right-click) and zoom (scroll wheel)

**Phase 2 --- The Economy (Week 2)**

Goal: Wire resource layer onto the visual foundation.

-   Aether generation from placed shapes

-   Shop panel --- buy and select shapes to place

-   Cost model including symmetry multiplier and color costs

-   Chromatic Dissonance penalty calculation

-   Chromatic Resonance diversity bonus

-   Basic UI --- resource counters, shop display

**Phase 3 --- Sigils & The Tome (Week 3)**

Goal: The discovery layer --- this is what makes it a game.

-   Adjacency graph --- each placed shape knows its neighbors

-   Sigil detection running after every placement

-   Tome UI --- records discovered Sigils, shows silhouettes for
    unknowns

-   Sparkle hints on edges for known Sigils

-   Sigil effects wired up --- flat generators and multipliers

-   Resonance awarded on Sigil discovery

**Phase 4 --- Prestige & Polish (Week 4)**

Goal: The loop that makes it replayable, plus final feel.

-   Archive mechanic --- freeze Mandala, begin new one

-   Background Mandala rendering --- archived Mandalas visible and
    generating

-   Resonance persistent unlock shop

-   Flux accumulation toward Convergence threshold

-   Convergence endgame sequence

-   Sound design and audio feedback

-   Final juice pass --- particles, screen effects, timing

**14. Technical Notes (Godot 4.6)**

**Core Data Structure**

> class_name MandalaPiece var shape_type: String \# triangle, square,
> pentagon, hexagon, octagon var color_tier: String \# grey, blue, red,
> purple, gold var size_tier: String \# small, normal, large, vast var
> position: Vector2 \# world position var rotation: float \# radians var
> symmetry_index: int \# which arm (0 = canonical, 1..N-1 = mirrors) var
> open_edges: Array \# Edge objects available for placement var
> neighbors: Array \# connected MandalaPiece references var
> active_sigils: Array \# Sigil instances this piece participates in

**Key Systems**

-   Symmetry math: mirror position = Arm0Position.rotated((2 \* PI / N)
    \* i) for each arm i

-   Adjacency: shared-edge detection between Polygon2D nodes using edge
    midpoint proximity

-   Sigil detection: graph scan checking local neighborhood pattern
    after each placement

-   Animations: Tween nodes for pulse/glow cycles; ShaderMaterial for
    color saturation and glow intensity

-   Camera: Camera2D with position lerp for pan inertia; zoom lerped
    between 0.3x and 3.0x

-   Starfield: two or three Node2D layers of small circle polygons with
    differing scroll speeds

-   Persistence: Resonance, Tome, unlocks, and archived Mandala data
    saved to JSON via FileAccess

**15. Open Design Questions**

Items to resolve during development:

-   Exact Sigil list --- finalize all 15--20 Sigils with tuned effects
    and costs.

-   Convergence threshold value --- needs playtesting to hit the 5--8
    prestige target.

-   Scholar Rank system --- what milestones, what bonuses? Needs detail.

-   Sound design direction --- ambient cosmic drone? Generative tones
    per shape type?

-   Archived Mandala layout --- do they drift to fixed positions or
    float organically?

-   Tutorial approach --- does the game need any onboarding, or is cold
    discovery enough?

-   Center shape selection UI --- how does the player choose their
    symmetry order at run start?

*--- End of Document ---*
