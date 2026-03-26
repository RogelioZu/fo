### 🎯 PROMPT PARA IA DE DISEÑO

```
Design an immersive event detail screen for "Finding Out" - combining the best of Eventbrite's info with Instagram's visual appeal.

STRUCTURE:

1. HERO SECTION (40% of screen):
   - Full-bleed image carousel (dots indicator)
   - Swipe for multiple event photos
   - Gradient overlay (bottom darker)
   - Floating back button (circle, blur background)
   - Floating action buttons: Share, Save/Bookmark, Calendar

2. TITLE AREA:
   - Category badge (colored chip with icon)
   - Event title (large, bold, 2 lines max)
   - Hosted by: Organizer avatar + name (tappable)

3. KEY INFO STRIP:
   - Horizontal scroll of info pills:
     - 📅 Date & Time
     - 📍 Distance (if location known)
     - 💵 Price / Free badge
     - 👥 Attendees count
   - Tappable for more details

4. ATTENDANCE SECTION (Prominent):
   - Large buttons side by side:
     - "Voy" (Going) - Solid primary button with check icon
     - "Me interesa" - Outlined with heart icon
   - Below: Attendee avatars row (overlapping circles)
   - "María, Juan y 48 más van" social proof text

5. FRIENDS ATTENDING (If any):
   - Special highlight card with warm background
   - "3 amigos van a este evento 🎉"
   - Avatar row with names
   - Creates FOMO / social motivation

6. QUICK ACTIONS ROW:
   - Icon buttons: Add to Calendar, Get Directions, Share with Friend
   - Horizontally spaced, labeled below each

7. ABOUT SECTION:
   - "Acerca del evento" header
   - Expandable text (3 lines preview + "Read more")
   - Tags/keywords at bottom

8. LOCATION SECTION:
   - Inline map preview (small, 120px height)
   - Address text below
   - "Open in Maps" and "Copy address" links
   - Distance from user's location

9. ORGANIZER SECTION:
   - Card with organizer info
   - Avatar, name, verified badge
   - Follower count, events hosted count
   - "Follow" and "Contact" buttons

10. RELATED EVENTS:
    - "También te puede gustar" section
    - Horizontal scroll of similar event cards
    - Based on category or same organizer

11. COMMENTS/HYPE SECTION:
    - "Comentarios" section
    - Show 2-3 most recent comments
    - "Ver todos los comentarios" link
    - Add comment input at bottom (avatar + text field)

BOTTOM PADDING: 100px for navbar

VISUAL:
- Image carousel feels premium
- Info is scannable at a glance
- CTAs (Going/Interested) are prominent
- Social proof everywhere
- Map adds credibility

OUTPUT: Full scrollable mockup with all sections. iPhone 14 Pro, light mode.
```

---

## 8. ✨ Create Event Screen

### Estado Actual
```
Elementos:
- AppBar "Crear Evento"
- Form fields: Título, Descripción, Categoría dropdown
- Image picker area
- Date/time selectors (inline row buttons)
- Address autocomplete field
- Map picker button
- Submit button "Crear Evento"
```

### Lo que Falta / Debe Mejorar
- ❌ Diseño muy formulario típico
- ❌ Sin preview de cómo se verá el evento
- ❌ Sin sugerencias/tips mientras escriben
- ❌ Sin templates para eventos comunes
- ❌ Sin guardado de borrador
- ❌ Sin opciones de tickets/pricing
- ❌ Sin co-hosts/colaboradores

### 🎯 PROMPT PARA IA DE DISEÑO

```
Design an inspiring event creation experience for "Finding Out" - make users excited to host events!

APPROACH: Progressive disclosure, step-by-step wizard (not overwhelming form)

STEP 1 - BASICS:
Header: "Let's create something amazing ✨"

- Event photo upload (large, prominent area)
  - Drag & drop zone with dashed border
  - Camera icon + "Add a stunning cover photo"
  - AI suggestion: "Tip: Events with photos get 5x more views"
  
- Title input (large, prominent)
  - Character counter
  - "What's your event called?"
  
- Category picker (grid of icons)
  - 8 categories with colorful icons
  - Single select, animated selection

"Continue" button at bottom

STEP 2 - WHEN & WHERE:

Date & Time Section:
- Visual calendar picker (inline, not pop-up)
- Time slots as selectable chips for quick selection
- Duration picker (1h, 2h, 3h, Custom)
- "Multi-day event" toggle

Location Section:
- Search bar for address
- "Use my current location" button
- Small map preview that updates
- "Select on map" for precision

"Continue" button

STEP 3 - DETAILS:

- Description textarea (larger, full width)
  - Formatting hints: bullet points, emojis encouraged
  - "Tell people what to expect..."
  
- Tags input (chips)
  - Suggested tags based on category
  
- Event Settings:
  - Public/Private toggle
  - Allow comments toggle
  - Capacity limit (optional number input)

- Pricing Section (collapsed by default):
  - Free event toggle (default on)
  - If paid: price input + currency
  - "Tickets via external link" option

STEP 4 - PREVIEW:

- "Here's how it looks! 🎉"
- Full preview mimicking the event detail screen
- Edit buttons on each section to go back
- Final "Publish Event" button (large, gradient, celebratory)

POST-PUBLISH:
- Confetti animation
- "Your event is live!" celebration screen
- Quick actions: Share, Invite friends, View event
- "Create another" link

PROGRESS:
- Top progress bar or step indicators
- Can swipe back anytime
- Save draft automatically (show "Draft saved" feedback)

VISUAL:
- Clean, spacious design
- Illustrations for each step (small, corner)
- Encouraging microcopy throughout
- Form should feel fun, not tedious

OUTPUT: Show all 4 steps as separate screens in a flow. iPhone 14 Pro.