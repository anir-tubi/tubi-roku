import * as os from 'os';
import * as path from 'path';

export const CIRCUIT_BREAKER_DIR = path.join(os.tmpdir(), 'rta-circuit-breaker');
export const CIRCUIT_BREAKER_THRESHOLD = 3;
