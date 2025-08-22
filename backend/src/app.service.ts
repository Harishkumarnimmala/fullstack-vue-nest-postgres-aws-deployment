import { Injectable } from '@nestjs/common';
import { Pool, PoolClient } from 'pg';

const useSsl = (process.env.DB_SSL || 'false').toLowerCase() === 'true';

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'apppass',
  ssl: useSsl ? { rejectUnauthorized: false } : undefined,
});

@Injectable()
export class AppService {
  async greeting() {
    const client = await pool.connect();
    try {
      await this.ensureSchemaAndSeed(client); // <-- make sure table exists

      const { rows } = await client.query(
        `SELECT name, street, zip, city, country
         FROM addresses
         ORDER BY random()
         LIMIT 1;`
      );

      if (!rows.length) {
        return { name: 'Guest', date: this.today(), address: 'No address found.' };
      }

      const r = rows[0];
      const address = `${r.street}, ${r.zip} ${r.city}, ${r.country}`;
      return { name: r.name, date: this.today(), address };
    } finally {
      client.release();
    }
  }

  private today() {
    return new Date().toLocaleDateString('en-GB', { year: 'numeric', month: 'long', day: 'numeric' });
  }

  // Create table if missing, and seed once if empty
  private async ensureSchemaAndSeed(client: PoolClient) {
    await client.query(`
      CREATE TABLE IF NOT EXISTS addresses (
        id SERIAL PRIMARY KEY,
        name VARCHAR(120) NOT NULL,
        street VARCHAR(200) NOT NULL,
        zip VARCHAR(20) NOT NULL,
        city VARCHAR(120) NOT NULL,
        country VARCHAR(120) NOT NULL
      );
    `);

    const { rows } = await client.query<{ count: string }>('SELECT COUNT(*) AS count FROM addresses;');
    if (Number(rows[0].count || 0) > 0) return;

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
}
