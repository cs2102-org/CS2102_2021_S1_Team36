import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { AppRoutingModule, routingComponents } from './app-routing.module';
import { AppComponent } from './app.component';
import { MatDialogModule } from '@angular/material/dialog';
import { ReactiveFormsModule } from '@angular/forms';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MenuHeaderComponent } from './components/general/menu-header/menu-header.component';
import { LoginComponent } from './components/general/login/login.component';
import { SignupComponent } from './components/general/signup/signup.component';
import { CaretakerSummaryPageComponent } from './components/caretaker/caretaker-summary-page/caretaker-summary-page.component';
import { CaretakerAvailabilityPageComponent } from './components/pet-owner/caretaker-availability-page/caretaker-availability-page.component';

@NgModule({
  declarations: [
    AppComponent,
    routingComponents,
    MenuHeaderComponent,
    LoginComponent,
    SignupComponent,
    CaretakerSummaryPageComponent,
    CaretakerAvailabilityPageComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    ReactiveFormsModule,
    MatDialogModule,
    NoopAnimationsModule
  ],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
