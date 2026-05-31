import {get} from '@vercel/blob';

const BLOB_KEY = 'latest-records.json';

function blobToken() {
  return process.env.BLOB_READ_WRITE_TOKEN || '';
}

export default async function handler(req, res) {
  try {
    const token = blobToken();
    if (!token) {
      res.status(500).json({
        ok: false,
        error: 'Missing BLOB_READ_WRITE_TOKEN. Link a Vercel Blob store to this project, enable it for the current environment, then redeploy.',
      });
      return;
    }
    const blob = await get(BLOB_KEY, {access: 'private', token});
    if (!blob) {
      res.status(404).json({ok: false, error: 'No collected data'});
      return;
    }
    const response = await fetch(blob.url, {
      cache: 'no-store',
      headers: blob.headers || {},
    });
    if (!response.ok) throw new Error(`Blob read failed: ${response.status}`);
    const payload = await response.json();
    res.setHeader('Cache-Control', 'no-store');
    res.status(200).json(payload);
  } catch (error) {
    res.status(500).json({ok: false, error: error.message});
  }
}
