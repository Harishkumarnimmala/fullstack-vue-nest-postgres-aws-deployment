'use strict';
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Pool } = require('pg');

const sm = new SecretsManagerClient({});
let poolPromise = null;

async function getPool() {
  if (poolPromise) return poolPromise;
  const secretArn = process.env.SECRET_ARN;
  if (!secretArn) throw new Error('SECRET_ARN not set');

  const res = await sm.send(new GetSecretValueCommand({ SecretId: secretArn }));
  const s = JSON.parse(res.SecretString || '{}');

  const pool = new Pool({
    host: process.env.PROXY_HOST || s.host,
    port: Number(s.port || 5432),
    database: s.dbname || 'appdb',
    user: s.username,
    password: s.password,
    ssl: { rejectUnauthorized: false }, // TLS for Aurora
    max: 2,
    idleTimeoutMillis: 5000
  });

  poolPromise = Promise.resolve(pool);
  return poolPromise;
}

async function ensureSchemaAndSeed(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS addresses (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      street TEXT NOT NULL,
      zip TEXT NOT NULL,
      city TEXT NOT NULL,
      country TEXT NOT NULL
    );
  `);

  const { rows } = await client.query('SELECT COUNT(*)::int AS c FROM addresses;');
  if ((rows[0]?.c || 0) > 0) return;

  await client.query(`
    INSERT INTO addresses (name, street, zip, city, country) VALUES
    ('Harish Kumar','Hauptstraße 12','77652','Offenburg','Germany'),
    ('Anita Patel','Kaiserstraße 8','76133','Karlsruhe','Germany'),
    ('Felix Müller','Bergweg 5','89073','Ulm','Germany'),
    ('Lena Schneider','Am Rathausplatz 3','79098','Freiburg im Breisgau','Germany'),
    ('Carlos Romero','Lindenallee 27','60311','Frankfurt am Main','Germany'),
    ('Sofia Rossi','Via Roma 14','20121','Milano','Italy'),
    ('Marek Nowak','Ulica Słoneczna 9','00-001','Warszawa','Poland'),
    ('Emma Johnson','Baker Street 221B','NW1 6XE','London','United Kingdom'),
    ('Noah Schmidt','Kirchstraße 4','10115','Berlin','Germany'),
    ('Ava Wagner','Seestraße 10','13353','Berlin','Germany'),
    ('Jonas Becker','Münchener Straße 2','80331','München','Germany'),
    ('Mia Weber','Domplatz 1','50667','Köln','Germany'),
    ('Lucas Fischer','Elbchaussee 99','22765','Hamburg','Germany'),
    ('Isabella Keller','Marktstraße 7','90402','Nürnberg','Germany'),
    ('Ethan Braun','Goethestraße 16','04109','Leipzig','Germany'),
    ('Olivia Hoffmann','Theaterplatz 2','01067','Dresden','Germany'),
    ('Liam Meier','Schlossallee 11','65183','Wiesbaden','Germany'),
    ('Charlotte Köhler','Neckarstraße 18','70173','Stuttgart','Germany'),
    ('Benjamin Vogel','Altstadtgasse 6','78462','Konstanz','Germany'),
    ('Emilia Richter','Königsallee 1','40212','Düsseldorf','Germany');
  `);
}

async function handleGreeting() {
  const pool = await getPool();
  const client = await pool.connect();
  try {
    await ensureSchemaAndSeed(client);
    const { rows } = await client.query(
      `SELECT name, street, zip, city, country
       FROM addresses
       ORDER BY random()
       LIMIT 1;`
    );
    const r = rows[0] || { name: 'Guest', street: '', zip: '', city: '', country: '' };
    const address = r.street + ', ' + r.zip + ' ' + r.city + ', ' + r.country;
    const today = new Date().toLocaleDateString('en-GB', { year:'numeric', month:'long', day:'numeric' });
    return { name: r.name, date: today, address };
  } finally {
    client.release();
  }
}

exports.handler = async (event) => {
  try {
    const path = (event && (event.rawPath || event.path)) || '/';
    if (path === '/healthz') {
      return { statusCode: 200, headers: { 'content-type':'application/json' }, body: JSON.stringify({ ok:true }) };
    }
    if (path === '/api/greeting') {
      const data = await handleGreeting();
      return { statusCode: 200, headers: { 'content-type':'application/json' }, body: JSON.stringify(data) };
    }
    return { statusCode: 404, headers: { 'content-type':'application/json' }, body: JSON.stringify({ message:'not found' }) };
  } catch (err) {
    console.error('handler error:', err && err.message || err);
    return { statusCode: 500, headers: { 'content-type':'application/json' }, body: JSON.stringify({ message:'Internal server error' }) };
  }
};
