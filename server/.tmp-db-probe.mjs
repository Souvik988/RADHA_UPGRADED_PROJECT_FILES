import postgres from 'postgres';

const sql = postgres({
  host: 'localhost',
  port: 5433,
  database: 'radha_dev',
  username: 'radha',
  password: 'radha_dev_password',
  ssl: false,
  max: 1,
  prepare: true,
  connection: {
    application_name: 'radha-api',
    statement_timeout: '30000',
  },
});

try {
  const rows = await sql`SELECT now() as now, current_database() as db, current_user as usr`;
  console.log('OK:', rows[0]);
} catch (err) {
  console.error('FAIL:', err.message);
  console.error(err.stack);
} finally {
  await sql.end();
}
