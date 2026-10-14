export const meta = {
  name: 'etech-mobile-phase2-resume',
  description: 'Finish Phase 2: add missing backend action endpoints (preprocess/analysis) + permission-gated state-aware action buttons across all 6 mobile modules, then analyze + screenshot',
  phases: [
    { title: 'Recon' },
    { title: 'Backend' },
    { title: 'Flutter' },
    { title: 'Integrate' },
    { title: 'Test' },
  ],
}

const FLUTTER = '/home/huytq/flutter/etech_lab'
const ODOO = '/home/huytq/elab_tech/elab-tech'

const INFRA = `
SHARED INFRA (reuse, do not reinvent):
- permissions (global PermissionController singleton): bool canWrite(String model), canCreate, canRead, canSeeMenu(xmlid), inGroup(groupXmlId). Default-allow on read/write before load.
- lib/widgets/status_chip.dart: StatusChip({required label, required color, IconData? icon}); StatusChip.fromState({required state, required label}); Color statusColorFor(String state).
- lib/widgets/module_list_scaffold.dart: ModuleDetailScaffold<T>({required String title, required Future<T> Function() load, required Widget Function(BuildContext, T data, VoidCallback reload) builder, List<Widget> actions=const[]}).
- Services send 'Cookie: session_id=<id>' header; have mock fallback. AppConfig.odooUrl is the base.
- Theme tokens via AppColors.* (primary, success, warning, danger, inkMuted, etc). App font is Inter.
`

// addon + endpoint per module. backendDone: action endpoints already exist (verified).
const MODULES = [
  { key: 'handovers', endpoint: '/api/handovers', addon: 'etech_field_sampling', model: 'etech.sampling.handover', backendDone: true },
  { key: 'lab_batches', endpoint: '/api/lab_batches', addon: 'etech_lab_test', model: 'etech.lab.analysis.batch', backendDone: true },
  { key: 'destructions', endpoint: '/api/destructions', addon: 'etech_sample_retention', model: 'etech.sample.destruction', backendDone: true },
  { key: 'test_reports', endpoint: '/api/test_reports', addon: 'etech_lab_test', model: 'etech.test.report', backendDone: true },
  { key: 'preprocess_requests', endpoint: '/api/preprocess_requests', addon: 'etech_lab_sample', model: 'etech.preprocess.request', backendDone: false },
  { key: 'analysis_requests', endpoint: '/api/analysis_requests', addon: 'etech_lab_sample', model: 'etech.analysis.request', backendDone: false },
]

const ACTION = { type: 'object', additionalProperties: false,
  required: ['slug', 'method', 'label', 'fromStates', 'needsReason', 'notes'],
  properties: {
    slug: { type: 'string', description: 'URL action_slug, e.g. receive (maps to action_receive)' },
    method: { type: 'string', description: 'model method, e.g. action_receive' },
    label: { type: 'string', description: 'Vietnamese button label' },
    fromStates: { type: 'array', items: { type: 'string' }, description: 'state values where action is valid (empty = always)' },
    needsReason: { type: 'boolean' },
    notes: { type: 'string' },
  } }

const RECON_SCHEMA = { type: 'object', additionalProperties: false,
  required: ['model', 'stateField', 'states', 'actions', 'existingSlugs'],
  properties: {
    model: { type: 'string' },
    stateField: { type: 'string', description: 'state/status field name; empty if none' },
    states: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['value', 'label'], properties: { value: { type: 'string' }, label: { type: 'string' } } } },
    actions: { type: 'array', items: ACTION },
    existingSlugs: { type: 'array', items: { type: 'string' }, description: 'action slugs already wired in the backend controller (empty if none yet)' },
  } }

// ---------- Recon: read state machine + existing backend wiring ----------
phase('Recon')
const recon = await parallel(MODULES.map((m) => () =>
  agent(
    `Read-only recon in Odoo backend ${ODOO} for mobile resource '${m.key}' (model ${m.model}, addon ${m.addon}, endpoint ${m.endpoint}).\n` +
    `1. Open ${m.addon}/controllers/mobile_api.py. Find any EXISTING POST action endpoint for ${m.endpoint}/<id>/<slug> and list the action slugs already wired (existingSlugs). ${m.backendDone ? 'These should already exist.' : 'There are likely none yet.'}\n` +
    `2. Open the model ${m.model} python file. Find its state/status selection field (stateField) and its full value list (states). Find ALL action_* methods that are real user-facing state-machine transitions (action_receive, action_done, action_cancel, action_start_*, action_create_*, action_approve, action_hand_over, action_return, etc). For each: a url slug (method without 'action_' prefix), the method name, a Vietnamese button label, the fromStates it is valid in, whether it needs a reason/reject wizard input (needsReason), and notes about preconditions (e.g. opens etech.reason.dialog wizard, requires signature).\n` +
    `Skip print/report/view-opening actions (action_print, action_open_*, action_view_*). Return the schema.`,
    { label: `recon:${m.key}`, phase: 'Recon', agentType: 'Explore', schema: RECON_SCHEMA }
  ).then(r => ({ module: m, recon: r }))
))
const reconOk = recon.filter(Boolean)

// ---------- Backend: add missing action endpoints (preprocess + analysis, same file) ----------
phase('Backend')
const pending = reconOk.filter(r => !r.module.backendDone && (r.recon?.actions?.length))
let backendNote = 'no missing backend endpoints'
if (pending.length) {
  backendNote = await agent(
    `Extend Odoo backend ${ODOO}, addon etech_lab_sample, file etech_lab_sample/controllers/mobile_api.py. Add POST action endpoints for these resources, calling the model's EXISTING action methods only (no new business logic — all validation stays in the model):\n\n` +
    pending.map(p => `RESOURCE '${p.module.key}' endpoint ${p.module.endpoint} model ${p.module.model}:\n${JSON.stringify(p.recon.actions, null, 2)}`).join('\n\n') + `\n\n` +
    `Pattern to mirror EXACTLY: the existing test_report_action / lab_batch_action handlers in etech_lab_test/controllers/mobile_api.py and destruction handlers in etech_sample_retention/controllers/mobile_api.py (type='http', auth='user', methods=['POST'], csrf=False; a _REPORT_ACTIONS-style slug->method map per resource; re-fetch record, check exists, check_access('write'), call the action, catch UserError/AccessError -> JSON {error} with 400/403/404, success -> {ok:true, id, state:<new state value>}).\n` +
    `Add ONE route per resource: POST ${pending[0].module.endpoint}/<int:rec_id>/<string:action_slug> (and the analogous one for the other resource). For needsReason actions, read 'reason' from the JSON body and feed it the way the model expects (check the model: if action opens etech.reason.dialog, replicate the minimal write/context the wizard does — look at how lab_batch cancel handled it). Use sudo only for technical metadata, never to bypass record rules.\n` +
    `Reuse the existing _body()/_json() helpers in that controller. Run a python syntax check (python -m py_compile) on the edited file. Return a one-paragraph summary of routes added + slug maps.`,
    { label: 'backend:lab_sample', phase: 'Backend' }
  )
}
log(`Backend: ${backendNote.slice ? backendNote.slice(0, 120) : backendNote}`)

// ---------- Flutter: action UI per module (own files, parallel) ----------
phase('Flutter')
const FLUTTER_SCHEMA = { type: 'object', additionalProperties: false,
  required: ['files', 'actionsWired', 'notes'],
  properties: { files: { type: 'array', items: { type: 'string' } }, actionsWired: { type: 'array', items: { type: 'string' } }, notes: { type: 'string' } } }

const flutter = await parallel(reconOk.map((r) => () => {
  const m = r.module
  const actions = (r.recon?.actions || [])
  return agent(
    `Flutter app ${FLUTTER}. Add permission-gated, state-aware ACTION BUTTONS to the '${m.key}' detail screen, wired to backend POST endpoints of the form POST ${m.endpoint}/<id>/<slug>.\n\n${INFRA}\n\n` +
    `Model: ${r.recon?.model}  stateField: ${r.recon?.stateField}\n` +
    `States: ${JSON.stringify(r.recon?.states)}\n` +
    `Actions (each -> POST ${m.endpoint}/<id>/<slug>):\n${JSON.stringify(actions, null, 2)}\n\n` +
    `Tasks:\n` +
    `1. In lib/services/${m.key}_service.dart add one write method per action: POST ${m.endpoint}/<id>/<slug> with session cookie + JSON body (include 'reason' for needsReason actions). Parse {ok,state} or throw the {error} message. Keep existing read methods + mock fallback intact.\n` +
    `2. In lib/screens/${m.key}_screens.dart detail view: render action buttons (bottom action bar / primary CTA) ONLY for actions whose fromStates includes the record's current state (if fromStates empty -> always) AND permissions.canWrite('${r.recon?.model}') is true. For needsReason actions open a reason dialog (TextField) before calling. On success: SnackBar + invoke the detail reload callback so the status chip refreshes. On error: show the message in a SnackBar. Disable buttons while the call is in flight.\n` +
    `3. Style with AppColors tokens: primary action = filled button; destructive (cancel/reject/return) = danger-colored outlined/text button.\n` +
    `ONLY edit lib/services/${m.key}_service.dart and lib/screens/${m.key}_screens.dart (other modules are edited in parallel — do not touch shared files). Run 'flutter analyze' scoped to these two files and fix their errors.\n` +
    `Return schema: files, actionsWired (labels), notes.`,
    { label: `flutter:${m.key}`, phase: 'Flutter', agentType: 'flutter-architect', schema: FLUTTER_SCHEMA }
  ).then(f => ({ module: m.key, model: r.recon?.model, flutter: f, actions: actions.map(a => a.label) }))
}))
const flutterOk = flutter.filter(Boolean)
log(`Flutter: ${flutterOk.length}/${reconOk.length} modules wired`)

// ---------- Integrate: whole-app analyze ----------
phase('Integrate')
const integrate = await agent(
  `Flutter app ${FLUTTER}. Run 'flutter analyze' across the WHOLE app and fix ALL errors introduced by the new action buttons/services (import paths, types, missing params, async gaps, unused imports). Do NOT change behavior of unrelated files. Iterate until 0 errors (pre-existing info-level lints in test/ may remain). Report the final analyze summary and any module whose actions did not wire cleanly.`,
  { label: 'integrate:analyze', phase: 'Integrate', schema: { type: 'object', additionalProperties: false, required: ['clean', 'summary'], properties: { clean: { type: 'boolean' }, summary: { type: 'string' } } } }
)

// ---------- Test: screenshot evidence of action buttons ----------
phase('Test')
const test = await agent(
  `Flutter app ${FLUTTER}. QA: produce SCREENSHOT EVIDENCE that the new DETAIL screens now show state-machine action buttons. Reuse the existing golden harness in test/mobile_screens_render_test.dart (mirror its setUpAll font-loading EXACTLY — Roboto + MaterialIcons + Inter from assets/fonts; palette via AppColors.apply(kLightPalette); iPhone-size view).\n\n` +
  `Add a NEW test file test/mobile_detail_actions_render_test.dart that pumps the DETAIL screen of each module: handovers, lab_batches, destructions, test_reports, preprocess_requests, analysis_requests — each with mock-fallback data in a state where at least one action button is visible (read each service mock to pick an id/state that enables an action; if needed set permissions to allow write). Capture each to test/screenshots/<module>_detail.png.\n` +
  `Run with: flutter test --update-goldens test/mobile_detail_actions_render_test.dart. Confirm 6 PNGs written and that action buttons appear. Do not hide failures.\n` +
  `Return: passed(bool), screenshots(absolute PNG paths written), summary, failures.`,
  { label: 'qa:detail-actions', phase: 'Test', agentType: 'flutter-tester', schema: { type: 'object', additionalProperties: false, required: ['passed', 'screenshots', 'summary'], properties: { passed: { type: 'boolean' }, screenshots: { type: 'array', items: { type: 'string' } }, summary: { type: 'string' }, failures: { type: 'string' } } } }
)

return {
  backend: backendNote,
  modules: flutterOk.map(r => ({ module: r.module, model: r.model, actions: r.actions, files: r.flutter?.files })),
  integrate,
  test,
}
