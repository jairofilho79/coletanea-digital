import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

// AWS Amplify configuration
import { Amplify } from 'aws-amplify';
import amplifyconfig from '../amplify_outputs.json';
Amplify.configure(amplifyconfig);

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
