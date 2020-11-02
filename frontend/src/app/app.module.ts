import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { AppRoutingModule, routingComponents } from './app-routing.module';
import { AppComponent } from './app.component';
import { MatDialogModule } from '@angular/material/dialog';
import { MatMenuModule } from '@angular/material/menu';
import { MatIconModule } from '@angular/material/icon';
import { ReactiveFormsModule } from '@angular/forms';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MenuHeaderComponent } from './components/general/menu-header/menu-header.component';
import { LoginComponent } from './components/general/login/login.component';
import { SignupComponent } from './components/general/signup/signup.component';
import { CaretakerSummaryPageComponent } from './components/caretaker/caretaker-summary-page/caretaker-summary-page.component';
import { CaretakerAvailabilityPageComponent } from './components/general/caretaker-availability-page/caretaker-availability-page.component';
import { AutoDropdownComponent } from './auto-dropdown.component';
import { PetOwnerBidsComponent } from './components/pet-owner/pet-owner-bids/pet-owner-bids.component';
import { CaretakerBidsComponent } from './components/caretaker/caretaker-bids/caretaker-bids.component';
import { StatsComponent } from './components/admin/stats/stats.component';
import { FullCalendarModule } from '@fullcalendar/angular';
import dayGridPlugin from '@fullcalendar/daygrid'; 
import interactionPlugin from '@fullcalendar/interaction'; 
import { HttpClientModule } from '@angular/common/http';
import {MatDatepickerModule} from '@angular/material/datepicker';
import { MatFormFieldModule } from '@angular/material/form-field';
import { ForumComponent } from './components/general/forum/forum.component';
import { CaretakerMakeBidComponent } from './components/general/caretaker-make-bid/caretaker-make-bid.component';
import { PetOwnerSummaryComponent } from './components/pet-owner/pet-owner-summary/pet-owner-summary.component';
import { SubmitRatingComponent } from './components/pet-owner/submit-rating/submit-rating.component';
import { BidDialogComponent } from './components/general/bid-dialog/bid-dialog.component';
import { ManageUsersComponent } from './components/admin/manage-users/manage-users.component';
import { FormNewCaretakerComponent } from './components/admin/form-new-caretaker/form-new-caretaker.component';
import { FormNewAdminComponent } from './components/admin/form-new-admin/form-new-admin.component';
import { FormNewPetTypeComponent } from './components/admin/form-new-pet-type/form-new-pet-type.component';

FullCalendarModule.registerPlugins([
  dayGridPlugin,
  interactionPlugin
]);

@NgModule({
  declarations: [
    AppComponent,
    routingComponents,
    MenuHeaderComponent,
    LoginComponent,
    SignupComponent,
    CaretakerSummaryPageComponent,
    CaretakerAvailabilityPageComponent,
    AutoDropdownComponent,
    PetOwnerBidsComponent,
    CaretakerBidsComponent,
    StatsComponent,
    ForumComponent,
    CaretakerMakeBidComponent,
    PetOwnerSummaryComponent,
    SubmitRatingComponent,
    BidDialogComponent,
    ManageUsersComponent,
    FormNewCaretakerComponent,
    FormNewAdminComponent,
    FormNewPetTypeComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    ReactiveFormsModule,
    MatDialogModule,
    NoopAnimationsModule,
    MatMenuModule,
    MatIconModule,
    FullCalendarModule,
    HttpClientModule,
    // MatDatepickerModule,
    // MatFormFieldModule,
  ],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
