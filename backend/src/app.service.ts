import { Injectable } from '@nestjs/common';
import { Pool } from 'pg';

// Create a single shared connection pool using environment variables
const useSsl =
  (process.env.DB_SSL || 'false').toLowerCase() === 'true';

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'apppass',
  // Enable TLS for RDS when requested. For a stricter setup, provide the RDS CA instead of rejectUnauthorized:false.
  ssl: useSsl ? { rejectUnauthorized: false } : undefined,
});

@Injectable()
export class AppService {
  async greeting() {
    const client = await pool.connect();
    try {
      // Pick a random row from the addresses table
      const { rows } = await client.query(
        `SELECT name, street, zip, city, country
         FROM addresses
         ORDER BY random()
         LIMIT 1;`
      );

      if (rows.length === 0) {
        // Helpful error if DB is empty or not seeded yet
        return { name: 'Guest', date: this.today(), address: 'No address found (seed DB).' };
      }

      const r = rows[0];
      const address = `${r.street}, ${r.zip} ${r.city}, ${r.country}`;

      return {
        name: r.name,
        date: this.today(),
        address,
      };
    } finally {
      client.release();
    }
  }

  private today() {
    // Human-friendly date like: 20 August 2025
    return new Date().toLocaleDateString('en-GB', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }
}
