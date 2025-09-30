// /srv/primarch/perf/k6_agents_load.js
import http from 'k6/http'; 
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    ramp: { 
      executor: 'ramping-arrival-rate',
      startRate: 10, 
      timeUnit: '1s',
      preAllocatedVUs: 200, 
      maxVUs: 1000,
      stages: [
        { target: 50, duration: '5m' },
        { target: 100, duration: '10m' },
        { target: 150, duration: '10m' }, // push ≥1000 conc via arrival rate
        { target: 0, duration: '2m' }
      ]
    }
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<950'],
  }
};

const BASE = __ENV.BASE || 'http://localhost:8080';

export default function () {
  const r = http.get(`${BASE}/v1/agents?include=health`);
  check(r, { '200': (x) => x.status === 200 });
  sleep(0.2);
}
