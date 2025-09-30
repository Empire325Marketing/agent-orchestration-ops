// /srv/primarch/perf/k6_agents_smoke.js
import http from 'k6/http'; 
import { check, sleep } from 'k6';

export const options = { 
  vus: 5, 
  duration: '2m',
  thresholds: { 
    http_req_failed: ['rate<0.01'], 
    http_req_duration: ['p(95)<950'] 
  } 
};

const BASE = __ENV.BASE || 'http://localhost:8080';

export default function () {
  // ping health, list agents, create+poll a tiny task (read-only demo endpoints)
  const r1 = http.get(`${BASE}/v1/health`);
  const r2 = http.get(`${BASE}/v1/agents`);
  
  check(r1, { 'health-ok': (r) => r.status === 200 });
  check(r2, { 'agents-ok': (r) => r.status === 200 });
  
  sleep(1);
}
