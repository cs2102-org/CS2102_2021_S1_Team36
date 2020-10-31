import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HomeComponent } from './components/general/home/home.component';
import { CaretakerAvailabilityPageComponent } from './components/general/caretaker-availability-page/caretaker-availability-page.component';
import { SignupComponent } from './components/general/signup/signup.component';
import { LoginComponent } from './components/general/login/login.component';
import { PetOwnerBidsComponent } from './components/pet-owner/pet-owner-bids/pet-owner-bids.component';
import { CaretakerBidsComponent } from './components/caretaker/caretaker-bids/caretaker-bids.component';
import { CaretakerSummaryPageComponent } from './components/caretaker/caretaker-summary-page/caretaker-summary-page.component';
import { ForumComponent } from './components/general/forum/forum.component';
import { CaretakerMakeBidComponent } from './components/general/caretaker-make-bid/caretaker-make-bid.component';
import { PetOwnerSummaryComponent } from './components/pet-owner/pet-owner-summary/pet-owner-summary.component';

const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'caretaker-availabilities', component: CaretakerAvailabilityPageComponent },
  { path: 'signup', component: SignupComponent },
  { path: 'petowner/bids', component: PetOwnerBidsComponent },
  { path: 'caretaker/bids', component: CaretakerBidsComponent },
  { path: 'caretaker/summary', component: CaretakerSummaryPageComponent },
  { path: 'forum', component: ForumComponent },
  { path: 'caretaker/bid/:caretaker', component: CaretakerMakeBidComponent },
  { path: 'petowner/summary', component: PetOwnerSummaryComponent }
];

@NgModule({
  declarations: [],
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }

export const routingComponents = [HomeComponent, CaretakerAvailabilityPageComponent];