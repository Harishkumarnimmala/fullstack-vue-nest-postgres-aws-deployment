import 'reflect-metadata';     // needed for NestJS decorators
import 'dotenv/config';        // loads .env (PORT, DB creds, etc.)
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Allow the Vue frontend to call the API from another origin
  app.enableCors({ origin: '*' });

  const port = Number(process.env.PORT || 3000);
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`API listening on http://localhost:${port}`);
}
bootstrap();
