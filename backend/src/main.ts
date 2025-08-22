import 'reflect-metadata';     // needed for NestJS decorators
import 'dotenv/config';        // loads .env (PORT, DB creds, etc.)
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { RequestMethod } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Add /api prefix for all routes, but keep /healthz without prefix for ALB checks
  app.setGlobalPrefix('api', {
    exclude: [{ path: 'healthz', method: RequestMethod.GET }],
  });

  const port = Number(process.env.PORT || 3000);
  await app.listen(port);
  console.log(`API listening on http://localhost:${port}`);
}
bootstrap();

