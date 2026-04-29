import * as crypto from 'crypto';
import * as os from 'os';
import * as path from 'path';

export const DEVICE_INFO_DIR = path.join(os.tmpdir(), 'rta-device-info');

// Hash absolute file paths into a fixed-length filename component.
export function fileKey(file: string): string {
  return crypto.createHash('sha1').update(file).digest('hex');
}
