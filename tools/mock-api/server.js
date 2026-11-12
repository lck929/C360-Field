const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const jsonServer = require('json-server');
const multer = require('multer');

const PORT = Number(process.env.PORT) || 3000;
const BASE = '/api/v1';
const SESSION_SECONDS = Number(process.env.SESSION_SECONDS) || 8 * 60 * 60;
const MAX_SELFIE_BYTES = 2 * 1024 * 1024;

const dbFile = path.join(__dirname, 'db.json');
const seedFile = path.join(__dirname, 'db.seed.json');
const uploadsDir = path.join(__dirname, 'uploads');

const args = process.argv.slice(2);
const argValues = (name) => args.flatMap((a, i) => (a === name && args[i + 1] ? [args[i + 1]] : []));

if (args.includes('--reset') || args.includes('--reset-only')) {
  fs.rmSync(dbFile, { force: true });
  fs.rmSync(uploadsDir, { recursive: true, force: true });
  console.log('Mock data reset.');
  if (args.includes('--reset-only')) process.exit(0);
}
if (!fs.existsSync(dbFile)) fs.copyFileSync(seedFile, dbFile);
fs.mkdirSync(uploadsDir, { recursive: true });

const server = jsonServer.create();
const router = jsonServer.router(dbFile);
const db = router.db;
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: MAX_SELFIE_BYTES } });

const pad = (n) => String(n).padStart(2, '0');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const fail = (res, status, error, message) => res.status(status).json({ error, message });
const settings = () => db.get('settings').value();
const localDay = (iso) => iso.slice(0, 10);
const isApiDate = (value) => /^\d{4}-\d{2}-\d{2}$/.test(value ?? '') && !Number.isNaN(Date.parse(value));

const normalizeBssid = (raw) =>
  String(raw ?? '')
    .trim()
    .toLowerCase()
    .replace(/-/g, ':')
    .split(':')
    .map((octet) => octet.padStart(2, '0'))
    .join(':');

const isoWithOffset = (d) => {
  const offset = -d.getTimezoneOffset();
  const sign = offset < 0 ? '-' : '+';
  const abs = Math.abs(offset);
  const date = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  const time = `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  return `${date}T${time}${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
};

const newAttendanceId = () => {
  let id;
  do id = `ATT-${10000 + crypto.randomInt(89999)}`;
  while (db.get('attendance').find({ id }).value());
  return id;
};

const projectFor = (employee) => db.get('projects').find({ id: employee.projectId }).value();

const findOrCreateEmployee = (employeeId) => {
  const id = employeeId.trim().toUpperCase();
  const existing = db.get('employees').find({ id }).value();
  if (existing) return existing;
  const template = db.get('employees').first().value();
  const employee = { ...template, id, employeeId: id, name: 'Field Technician' };
  db.get('employees').push(employee).write();
  return employee;
};

const issueSession = (employee) => {
  const now = Date.now();
  db.get('sessions').remove((s) => s.expiresAt < now).write();
  const token = `mock.${crypto.randomBytes(24).toString('base64url')}`;
  db.get('sessions').push({ token, employeeId: employee.id, expiresAt: now + SESSION_SECONDS * 1000 }).write();
  return { token, expiresIn: SESSION_SECONDS };
};

const requireAuth = (req, res, next) => {
  const match = /^Bearer\s+(.+)$/i.exec(req.get('Authorization') ?? '');
  if (!match) return fail(res, 401, 'UNAUTHORIZED', 'Missing bearer token');
  const session = db.get('sessions').find({ token: match[1] }).value();
  if (!session || session.expiresAt < Date.now()) return fail(res, 401, 'TOKEN_EXPIRED', 'Session expired, sign in again');
  const employee = db.get('employees').find({ id: session.employeeId }).value();
  if (!employee) return fail(res, 401, 'TOKEN_EXPIRED', 'Session expired, sign in again');
  req.employee = employee;
  next();
};

const profileJson = (employee) => {
  const project = projectFor(employee);
  return {
    employeeId: employee.employeeId,
    name: employee.name,
    trade: employee.trade,
    faceEnrolled: employee.faceEnrolled,
    project: {
      id: project.id,
      name: project.name,
      wifiBssids: project.wifiBssids,
      shift: project.shift,
    },
  };
};

const seedHistory = (employee) => {
  if (db.get('seeded').includes(employee.id).value()) return;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const project = projectFor(employee);
  let added = 0;
  for (let offset = 1; added < 5; offset++) {
    const day = new Date(today.getFullYear(), today.getMonth(), today.getDate() - offset);
    if (day.getDay() === 0) continue;
    const checkIn = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 6, 46 + ((added * 5) % 13));
    const checkOut = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 17, (added * 11) % 16);
    for (const [type, at] of [['IN', checkIn], ['OUT', checkOut]]) {
      db.get('attendance')
        .push({
          id: newAttendanceId(),
          clientId: `seed-${employee.id}-${at.getTime()}`,
          employeeId: employee.id,
          type,
          capturedAt: isoWithOffset(at),
          bssid: project.wifiBssids[0],
          status: 'VERIFIED',
          receivedAt: new Date().toISOString(),
        })
        .write();
    }
    added++;
  }
  db.get('seeded').push(employee.id).write();
};

const registerBssids = (values) => {
  const project = db.get('projects').first();
  const current = project.get('wifiBssids').value();
  const added = values.map(normalizeBssid).filter((b) => /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/.test(b) && !current.includes(b));
  if (added.length) project.assign({ wifiBssids: [...current, ...added] }).write();
  return project.get('wifiBssids').value();
};

registerBssids([...argValues('--bssid'), ...(process.env.SITE_BSSIDS ?? '').split(',').filter(Boolean)]);

server.use(jsonServer.defaults({ logger: true }));
server.use(jsonServer.bodyParser);

server.use(BASE, async (req, res, next) => {
  if (req.path.startsWith('/_mock')) return next();
  const s = settings();
  if (s.latencyMs > 0) await sleep(s.latencyMs);
  if (s.serverError) return fail(res, 503, 'SERVICE_UNAVAILABLE', 'Service temporarily unavailable');
  next();
});

server.post(`${BASE}/auth/login`, (req, res) => {
  const { employeeId, password } = req.body ?? {};
  if (typeof employeeId !== 'string' || !employeeId.trim()) {
    return fail(res, 400, 'VALIDATION_ERROR', 'employeeId is required');
  }
  if (typeof password !== 'string' || !password || password === 'wrong') {
    return fail(res, 401, 'INVALID_CREDENTIALS', 'Employee ID or password is incorrect');
  }
  res.json(issueSession(findOrCreateEmployee(employeeId)));
});

server.post(`${BASE}/auth/microsoft`, (req, res) => {
  const { idToken } = req.body ?? {};
  if (typeof idToken !== 'string' || !idToken) return fail(res, 400, 'VALIDATION_ERROR', 'idToken is required');
  res.json(issueSession(db.get('employees').first().value()));
});

server.get(`${BASE}/me`, requireAuth, (req, res) => {
  res.json(profileJson(req.employee));
});

const selfieUpload = (req, res, next) =>
  upload.single('selfie')(req, res, (err) => {
    if (!err) return next();
    if (err.code === 'LIMIT_FILE_SIZE') return fail(res, 413, 'PAYLOAD_TOO_LARGE', 'Selfie is larger than 2 MB');
    return fail(res, 400, 'VALIDATION_ERROR', err.message);
  });

server.post(`${BASE}/attendance`, requireAuth, selfieUpload, (req, res) => {
  const employee = req.employee;
  const { clientId, type, capturedAt, bssid } = req.body ?? {};
  if (!clientId) return fail(res, 400, 'VALIDATION_ERROR', 'clientId is required');
  if (type !== 'IN' && type !== 'OUT') return fail(res, 400, 'VALIDATION_ERROR', 'type must be IN or OUT');
  if (!/^\d{4}-\d{2}-\d{2}T/.test(capturedAt ?? '') || Number.isNaN(Date.parse(capturedAt))) {
    return fail(res, 400, 'VALIDATION_ERROR', 'capturedAt must be ISO 8601 with offset');
  }

  const existing = db.get('attendance').find({ clientId, employeeId: employee.id }).value();
  if (existing) return res.status(200).json({ id: existing.id, status: existing.status, duplicate: true });

  if (!projectFor(employee).wifiBssids.includes(normalizeBssid(bssid))) {
    return fail(res, 403, 'NOT_ON_SITE_NETWORK', 'BSSID not registered for the project');
  }
  if (!req.file) return fail(res, 422, 'MISSING_PHOTO', 'selfie is required');
  if (req.file.size === 0) return fail(res, 422, 'NO_FACE_FOUND', 'No usable face in the image');
  if (!settings().faceMatches) return fail(res, 422, 'FACE_NOT_MATCHED', 'Selfie doesn’t match the enrolled face');

  const sameDay = db
    .get('attendance')
    .filter((r) => r.employeeId === employee.id && localDay(r.capturedAt) === localDay(capturedAt))
    .value();
  const hasIn = sameDay.some((r) => r.type === 'IN');
  const hasOut = sameDay.some((r) => r.type === 'OUT');
  if (type === 'IN' ? hasIn : !hasIn || hasOut) return fail(res, 409, 'SEQUENCE_ERROR', 'Out of sequence');

  const id = newAttendanceId();
  fs.writeFileSync(path.join(uploadsDir, `${id}.jpg`), req.file.buffer);
  db.get('attendance')
    .push({
      id,
      clientId,
      employeeId: employee.id,
      type,
      capturedAt,
      bssid: normalizeBssid(bssid),
      status: 'VERIFIED',
      selfieBytes: req.file.size,
      receivedAt: new Date().toISOString(),
    })
    .write();
  res.status(201).json({ id, status: 'VERIFIED' });
});

server.get(`${BASE}/attendance`, requireAuth, (req, res) => {
  const { from, to } = req.query;
  if (!isApiDate(from) || !isApiDate(to)) return fail(res, 400, 'VALIDATION_ERROR', 'from and to must be YYYY-MM-DD');
  if (from > to) return fail(res, 400, 'VALIDATION_ERROR', 'from must not be after to');
  seedHistory(req.employee);
  const items = db
    .get('attendance')
    .filter((r) => r.employeeId === req.employee.id && localDay(r.capturedAt) >= from && localDay(r.capturedAt) <= to)
    .sortBy((r) => Date.parse(r.capturedAt))
    .reverse()
    .map(({ id, type, capturedAt, status }) => ({ id, type, capturedAt, status }))
    .value();
  res.json({ from, to, items });
});

server.get(`${BASE}/_mock/settings`, (req, res) => {
  res.json({ ...settings(), wifiBssids: db.get('projects').first().get('wifiBssids').value() });
});

server.patch(`${BASE}/_mock/settings`, (req, res) => {
  const body = req.body ?? {};
  const change = {};
  if (typeof body.faceMatches === 'boolean') change.faceMatches = body.faceMatches;
  if (typeof body.serverError === 'boolean') change.serverError = body.serverError;
  if (Number.isInteger(body.latencyMs) && body.latencyMs >= 0) change.latencyMs = body.latencyMs;
  db.get('settings').assign(change).write();
  res.json(settings());
});

server.post(`${BASE}/_mock/bssids`, (req, res) => {
  const values = [req.body?.bssid, ...(Array.isArray(req.body?.bssids) ? req.body.bssids : [])].filter(Boolean);
  if (!values.length) return fail(res, 400, 'VALIDATION_ERROR', 'bssid is required');
  res.json({ wifiBssids: registerBssids(values) });
});

server.use(BASE, (req, res) => fail(res, 404, 'NOT_FOUND', `${req.method} ${BASE}${req.path} does not exist`));

server.use('/db', router);

server.use((err, req, res, next) => {
  console.error(err);
  if (res.headersSent) return next(err);
  fail(res, 500, 'INTERNAL_ERROR', 'Unexpected server error');
});

const reloadFromDisk = () => {
  let text;
  try {
    text = fs.readFileSync(dbFile, 'utf8');
  } catch {
    return;
  }
  if (text === JSON.stringify(db.getState(), null, 2)) return;
  try {
    const seed = JSON.parse(fs.readFileSync(seedFile, 'utf8'));
    db.setState({ ...seed, ...JSON.parse(text) });
    console.log('db.json changed on disk, reloaded');
  } catch (err) {
    console.warn(`db.json changed but is not valid JSON yet, keeping the old data (${err.message})`);
  }
};

fs.watchFile(dbFile, { interval: 500 }, (curr, prev) => {
  if (curr.mtimeMs !== prev.mtimeMs) reloadFromDisk();
});

server.listen(PORT, '0.0.0.0', () => {
  const lanIps = Object.values(os.networkInterfaces())
    .flat()
    .filter((i) => i && i.family === 'IPv4' && !i.internal)
    .map((i) => i.address);
  console.log(`C360 mock API listening on port ${PORT}`);
  console.log(`Site BSSIDs: ${db.get('projects').first().get('wifiBssids').value().join(', ')}`);
  for (const ip of lanIps) {
    console.log(`  flutter run --dart-define=API_BASE_URL=http://${ip}:${PORT}${BASE}`);
  }
  console.log(`  Android emulator: --dart-define=API_BASE_URL=http://10.0.2.2:${PORT}${BASE}`);
});
