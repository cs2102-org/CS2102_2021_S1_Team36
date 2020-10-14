import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HomeComponent } from './components/general/home/home.component';
import { CaretakerAvailabilityPageComponent } from './components/pet-owner/caretaker-availability-page/caretaker-availability-page.component';
import { SignupComponent } from './components/general/signup/signup.component';

const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'caretaker-availabilities', component: CaretakerAvailabilityPageComponent },
  { path: 'signup', component: SignupComponent },
];

@NgModule({
  declarations: [],
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }

export const routingComponents = [HomeComponent, CaretakerAvailabilityPageComponent];