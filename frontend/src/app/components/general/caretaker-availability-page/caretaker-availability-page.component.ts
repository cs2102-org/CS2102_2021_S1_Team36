import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import {MatDatepickerModule} from '@angular/material/datepicker';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';

@Component({
  selector: 'app-caretaker-availability-page',
  templateUrl: './caretaker-availability-page.component.html',
  styleUrls: ['./caretaker-availability-page.component.css']
})
export class CaretakerAvailabilityPageComponent implements OnInit {
  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  datesSelected: String[] = [];

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    height: 450,
    dateClick: this.handleDateClick.bind(this),
    events: [
      { title: 'event 1', date: '2019-04-01' },
      { title: 'event 2', date: '2019-04-02' }
    ]
  };

  filterForm = new FormGroup({
    search: new FormControl(''),
    dateFrom: new FormControl(''),
    dateTo: new FormControl(''),
    petType: new FormControl(''),
    priceFrom: new FormControl(''),
    priceTo: new FormControl(''),
    minRating: new FormControl('')
  });

  caretakers: any[] = [
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    
  ];

  constructor() { }

  ngOnInit(): void {
  }

  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }

  handleDateClick(arg) {
    this.datesSelected.push(arg.dateStr);
  }

}


    // { name: 'Narco' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Bombasto' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Celeritas' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Magneta' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'RubberMan' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Dynama' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Dr IQ' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Magma' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Tornado' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Dr Nice' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Narco' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Bombasto' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Celeritas' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Magneta' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'RubberMan' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Dynama' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']},
    // { name: 'Dr IQ' , Rating: 5, from: 1, to: 5, price: 20, pets: ['sad', 'asd']}