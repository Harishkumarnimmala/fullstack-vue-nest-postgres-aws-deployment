import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  // existing
  @Get('/greeting')
  getGreeting() {
    return this.appService.greeting();
  }

  // NEW: API-prefixed alias so CloudFront route /api/* works
  @Get('/api/greeting')
  getGreetingApi() {
    return this.appService.greeting();
  }

  @Get('/healthz')
  health() {
    return { ok: true };
  }

  // NEW: API-prefixed health alias (optional)
  @Get('/api/healthz')
  healthApi() {
    return { ok: true };
  }
}
