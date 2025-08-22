import 'reflect-metadata';     // Nest decorators
import 'dotenv/config';        // optional in local dev
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // IMPORTANT: no global prefix here (CF already strips /api)
  // app.setGlobalPrefix('api');  // <-- removed

  // Bind to all interfaces for ECS/ALB
  const port = Number(process.env.PORT || 3000);
  await app.listen(port, '0.0.0.0');
  console.log(`API listening on http://0.0.0.0:${port}`);
}
bootstrap();
