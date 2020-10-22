import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import {MatDatepickerModule} from '@angular/material/datepicker';

@Component({
  selector: 'app-caretaker-availability-page',
  templateUrl: './caretaker-availability-page.component.html',
  styleUrls: ['./caretaker-availability-page.component.css']
})
export class CaretakerAvailabilityPageComponent implements OnInit {
  filterForm = new FormGroup({
    search: new FormControl(''),
    date: new FormControl(''),
    petType: new FormControl(''),
    price: new FormControl(''),
    minRating: new FormControl('')
  });

  heroes: any[] = [
    { id: 1, name: 'Dr Nice', Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd'] },
    { id: 2, name: 'Narco' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 3, name: 'Bombasto' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 4, name: 'Celeritas' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 5, name: 'Magneta' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 6, name: 'RubberMan' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 7, name: 'Dynama' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 8, name: 'Dr IQ' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 9, name: 'Magma' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 10, name: 'Tornado' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 1, name: 'Dr Nice' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 2, name: 'Narco' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 3, name: 'Bombasto' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 4, name: 'Celeritas' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 5, name: 'Magneta' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 6, name: 'RubberMan' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 7, name: 'Dynama' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    { id: 8, name: 'Dr IQ' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']}
  ];

  selectedHero;

  constructor() { }

  ngOnInit(): void {
  }

  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }
}


      //  <span class="badge">{{hero.id}}</span> 


//                   <<mat-form-field appearance="fill">
//   <mat-label>Enter a date range</mat-label>
//   <mat-date-range-input [formGroup]="range" [rangePicker]="picker">
//     <input matStartDate formControlName="start" placeholder="Start date">
//     <input matEndDate formControlName="end" placeholder="End date">
//   </mat-date-range-input>
//   <mat-datepicker-toggle matSuffix [for]="picker"></mat-datepicker-toggle>
//   <mat-date-range-picker #picker></mat-date-range-picker>

//   <mat-error *ngIf="range.controls.start.hasError('matStartDateInvalid')">Invalid start date</mat-error>
//   <mat-error *ngIf="range.controls.end.hasError('matEndDateInvalid')">Invalid end date</mat-error>
// </mat-form-field>

// new FormGroup({
//       start: new FormControl(),
//       end: new FormControl()
//     })