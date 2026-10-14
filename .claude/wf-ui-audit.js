export const meta = {
  name: 'etech-mobile-ui-audit',
  description: 'UI/UX + design review of the Flutter app with screenshot evidence: fix evidence-blocking render artifacts, audit across design lenses (light+dark), auto-fix findings, re-render and re-review until it passes professional quality',
  phases: [
    { title: 'Capture' },
    { title: 'Review' },
    { title: 'Fix' },
    { title: 'Recapture' },
    { title: 'Final' },
  ],
}

const APP = '/home/huytq/flutter/etech_lab'
const SHOTS = `${APP}/test/screenshots`

// Screens to put under audit. detail screens already render action buttons.
const SCREENS = [
  'login', 'home', 'notifications', 'account',
  'handovers (list+detail)', 'lab_batches (list+detail)', 'destructions (list+detail)',
  'test_reports (list+detail)', 'preprocess_requests (list+detail)', 'analysis_requests (list+detail)',
  'customers (list)',
]

const HARNESS_NOTE = `
RENDER HARNESS (reuse EXACTLY, do not reinvent):
- test/mobile_screens_render_test.dart and test/mobile_detail_actions_render_test.dart already pump screens with mock-fallback data and dump PNGs to test/screenshots/.
- Their setUpAll loads real fonts: Roboto + MaterialIcons from the material_fonts cache dir, and Inter (Regular/Medium/SemiBold/Bold/Italic) from ${APP}/assets/fonts. Inter carries the Vietnamese glyphs.
- Palette is applied via AppColors.apply(kLightPalette) (or kDarkPalette for dark). iPhone-ish view (390x844 @3x). Run with: flutter test --update-goldens <file>.
- KNOWN EVIDENCE-BLOCKING BUG: the top header / app-bar region currently renders as solid BLACK BOXES in the goldens (the title + leading/action icons), while body text renders fine. This must be diagnosed and fixed so the header shows real text+icons — otherwise the screenshots are not trustworthy evidence. Likely causes to check: an AppBar/header titleTextStyle or icon font that isn't covered by the loaded fonts in test mode, a MaterialIcons family-name mismatch, or a custom header widget using a font/weight not loaded. Fix it in the HARNESS font-loading (preferred) and/or the shared header widget if it hardcodes a missing font — do NOT degrade the real app's styling.
`

const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['lens', 'verdict', 'findings', 'summary'],
  properties: {
    lens: { type: 'string' },
    verdict: { type: 'string', enum: ['pass', 'fail'], description: 'pass = professional, ship-quality for this lens; fail = has issues worth fixing' },
    findings: { type: 'array', items: { type: 'object', additionalProperties: false,
      required: ['screen', 'severity', 'category', 'issue', 'suggestedFix', 'targetFile'],
      properties: {
        screen: { type: 'string' },
        severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
        category: { type: 'string', description: 'e.g. spacing, alignment, typography, contrast, color, overflow, touch-target, empty-state, hierarchy, consistency' },
        issue: { type: 'string', description: 'what is wrong, referencing the screenshot' },
        suggestedFix: { type: 'string' },
        targetFile: { type: 'string', description: 'best-guess Flutter file to edit (lib/...), or "" if unknown' },
      } } },
    summary: { type: 'string' },
  },
}

const LENSES = [
  { key: 'visual-design', agentType: 'flutter-ui-ux', prompt:
    `You are a senior product DESIGNER doing a critical design review. Judge overall visual quality, professionalism and trustworthiness: visual hierarchy, balance, use of whitespace, card/elevation system, brand consistency, whether it looks like a polished commercial app vs a prototype. Be demanding but specific — every finding must point at a concrete screenshot and a concrete fix.` },
  { key: 'layout-overflow', agentType: 'flutter-ui-ux', prompt:
    `You are a UI engineer reviewing LAYOUT correctness: alignment, consistent padding/margins/gutters, list item rhythm, action-bar placement, safe-area, and especially Vietnamese long-text overflow/truncation/wrapping (labels like "Đã chuyển phân tích", "Đã hoàn thành sơ chế"). Flag any clipping, overlap, misalignment, or cramped touch targets (<48dp).` },
  { key: 'typography-color', agentType: 'flutter-ui-ux', prompt:
    `You are a design-systems reviewer focused on TYPOGRAPHY + COLOR: type scale consistency, font weights, line-height, label vs value contrast, status-chip color semantics, WCAG text contrast, and theme-token consistency. Review BOTH light and dark screenshots — dark-mode contrast/легibility is in scope. Flag low-contrast text, off-palette colors, inconsistent chip colors.` },
  { key: 'states-a11y', agentType: 'flutter-tester', prompt:
    `You are a QA reviewer focused on STATES + interaction integrity: empty states, loading, error states, the action buttons rendered on detail screens (are the right buttons shown for the record state? are destructive actions visually distinct? are there dead/duplicate/overlapping controls?), and the black-box header artifact if still present. Flag anything that reads as broken or unfinished.` },
]

function keyOf(f) { return `${f.targetFile || 'unknown'}` }

// ---------------- Phase 1: capture clean evidence ----------------
phase('Capture')
const capture = await agent(
  `Flutter app ${APP}. Produce CLEAN screenshot evidence of the app's screens for a design review.\n\n${HARNESS_NOTE}\n\n` +
  `Tasks:\n` +
  `1. FIRST fix the black-box header artifact described above so headers render real text+icons in goldens. Diagnose by reading the relevant screen/header widget + the harness font loading. Verify by re-rendering and visually opening a PNG.\n` +
  `2. Ensure these screens are captured to ${SHOTS}/ with mock-fallback data (no backend): ${SCREENS.join(', ')}. Reuse/extend the two existing render test files; if a screen isn't covered, add it. Use realistic mock data that exercises status chips and action buttons.\n` +
  `3. Also capture DARK-MODE variants of at least: home, one list screen, one detail screen (AppColors.apply(kDarkPalette)) as <name>_dark.png.\n` +
  `Run the render tests with --update-goldens. Open several PNGs to visually confirm headers render correctly now. Do NOT change app styling just to pass — only fix genuine harness/render issues.\n` +
  `Return JSON: {headerFixed:bool, screenshots:[absolute paths], notes:string}.`,
  { label: 'capture:evidence', phase: 'Capture', agentType: 'flutter-tester',
    schema: { type: 'object', additionalProperties: false, required: ['headerFixed', 'screenshots', 'notes'],
      properties: { headerFixed: { type: 'boolean' }, screenshots: { type: 'array', items: { type: 'string' } }, notes: { type: 'string' } } } }
)
log(`Capture: headerFixed=${capture?.headerFixed}, ${capture?.screenshots?.length || 0} screenshots`)

// ---------------- Fix loop: review -> fix -> recapture, until pass ----------------
const MAX_ROUNDS = 3
const history = []
let lastReviews = []
let round = 0

while (round < MAX_ROUNDS) {
  round++
  phase('Review')
  const reviews = (await parallel(LENSES.map(l => () =>
    agent(
      `${l.prompt}\n\nApp: ${APP}. Review the screenshots in ${SHOTS}/ — READ each PNG image (light and *_dark variants). Screens under audit: ${SCREENS.join(', ')}.\n` +
      `This is review round ${round}. Only report issues that genuinely hurt a professional, high-trust product. For each finding give the screen, severity, category, the concrete problem visible in the image, a concrete fix, and the best-guess Flutter file to edit. If this lens is already ship-quality, return verdict="pass" with an empty findings array.\n` +
      `Return the schema.`,
      { label: `review:${l.key}#${round}`, phase: 'Review', agentType: l.agentType, schema: FINDINGS_SCHEMA }
    )
  ))).filter(Boolean)
  lastReviews = reviews

  const actionable = reviews.flatMap(r => r.findings).filter(f => f.severity !== 'low')
  const passes = reviews.filter(r => r.verdict === 'pass').length
  history.push({ round, lensVerdicts: reviews.map(r => `${r.lens}:${r.verdict}`), actionable: actionable.length })
  log(`Round ${round}: ${passes}/${reviews.length} lenses pass, ${actionable.length} actionable findings`)

  if (!actionable.length) { log(`All lenses clean at round ${round}.`); break }
  if (round === MAX_ROUNDS) { log(`Hit max rounds (${MAX_ROUNDS}); applying final fix pass.`); }

  // group findings by target file so parallel fixers don't collide on the same file
  const groups = {}
  for (const f of actionable) {
    const k = keyOf(f)
    ;(groups[k] = groups[k] || []).push(f)
  }
  phase('Fix')
  await parallel(Object.entries(groups).map(([file, fs]) => () =>
    agent(
      `Flutter app ${APP}. Apply these design-review fixes${file !== 'unknown' ? ` to ${file} (and only files it directly owns)` : ' (locate the right file yourself; touch only what each fix needs)'}:\n\n` +
      fs.map((f, i) => `${i + 1}. [${f.severity}/${f.category}] ${f.screen}: ${f.issue}\n   FIX: ${f.suggestedFix}`).join('\n\n') + `\n\n` +
      `Use the app's design tokens (AppColors.*, theme typography, existing radii/shadows). Keep changes minimal and on-altitude — fix the reported issue without redesigning unrelated parts and without breaking other screens that may share the widget. Do NOT touch backend/Odoo. Run 'flutter analyze' on the files you edit and fix any errors you introduce.\n` +
      `Return JSON: {filesEdited:[...], applied:[short desc per fix], skipped:[fix + why]}.`,
      { label: `fix:${file.split('/').pop()}#${round}`, phase: 'Fix', agentType: 'flutter-ui-ux',
        schema: { type: 'object', additionalProperties: false, required: ['filesEdited', 'applied'],
          properties: { filesEdited: { type: 'array', items: { type: 'string' } }, applied: { type: 'array', items: { type: 'string' } }, skipped: { type: 'array', items: { type: 'string' } } } } }
    )
  ))

  phase('Recapture')
  await agent(
    `Flutter app ${APP}. Re-render ALL audit screenshots so the evidence reflects the just-applied UI fixes. Reuse the existing render test files; run them with --update-goldens. ${HARNESS_NOTE}\n` +
    `Confirm the PNGs in ${SHOTS}/ are regenerated (light + *_dark) and open a few to sanity-check nothing regressed. Return JSON: {rerendered:bool, count:number, notes:string}.`,
    { label: `recapture#${round}`, phase: 'Recapture', agentType: 'flutter-tester',
      schema: { type: 'object', additionalProperties: false, required: ['rerendered', 'count', 'notes'],
        properties: { rerendered: { type: 'boolean' }, count: { type: 'number' }, notes: { type: 'string' } } } }
  )
}

// ---------------- Final: analyze + verdict ----------------
phase('Final')
const final = await agent(
  `Flutter app ${APP}. Final QA gate after the UI/UX audit + fix loop:\n` +
  `1. Run 'flutter analyze' on the whole app — report errors (must be 0; pre-existing info lints in test/ may remain).\n` +
  `2. Run 'flutter test' (the render/golden tests at minimum) and report pass/fail.\n` +
  `3. READ the final screenshots in ${SHOTS}/ (light + dark) and give an honest senior-designer verdict on whether the app now looks like a professional, high-trust product. List any remaining nits (non-blocking).\n` +
  `Return JSON: {analyzeClean:bool, testsPass:bool, designVerdict:string, professional:bool, remainingNits:[...], screenshots:[absolute paths]}.`,
  { label: 'final:gate', phase: 'Final', agentType: 'flutter-tester',
    schema: { type: 'object', additionalProperties: false, required: ['analyzeClean', 'testsPass', 'professional', 'designVerdict'],
      properties: { analyzeClean: { type: 'boolean' }, testsPass: { type: 'boolean' }, professional: { type: 'boolean' }, designVerdict: { type: 'string' }, remainingNits: { type: 'array', items: { type: 'string' } }, screenshots: { type: 'array', items: { type: 'string' } } } } }
)

return { capture, rounds: history, lastReviews: lastReviews.map(r => ({ lens: r.lens, verdict: r.verdict, summary: r.summary })), final }
