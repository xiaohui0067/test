import {put} from '@vercel/blob';
import {collectLotteryData} from './_lib/lottery-pipeline.js';

const BLOB_KEY = 'latest-records.json';

function blobToken() {
  return process.env.BLOB_READ_WRITE_TOKEN || '';
}

function allowed(req) {
  const secret = process.env.COLLECT_SECRET;
  if (!secret) return true;
  return req.headers['x-collect-secret'] === secret || req.query?.secret === secret;
}

export default async function handler(req, res) {
  if (req.method !== 'POST' && req.method !== 'GET') {
    res.status(405).json({ok: false, error: 'Method not allowed'});
    return;
  }
  if (!allowed(req)) {
    res.status(401).json({ok: false, error: 'Unauthorized'});
    return;
  }
  try {
    const token = blobToken();
    if (!token) {
      res.status(500).json({
        ok: false,
        error: 'Missing BLOB_READ_WRITE_TOKEN. Link a Vercel Blob store to this project, enable it for the current environment, then redeploy.',
      });
      return;
    }
    const payload = await collectLotteryData();
    const blob = await put(BLOB_KEY, JSON.stringify(payload), {
      access: 'private',
      contentType: 'application/json; charset=utf-8',
      allowOverwrite: true,
      token,
    });
    res.status(200).json({ok: true, url: blob.url, summary: payload.summary, collect: payload.collect});
  } catch (error) {
    res.status(500).json({ok: false, error: error.message});
  }
}
