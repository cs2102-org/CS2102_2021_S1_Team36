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

  selectedCaretaker;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    height: 450,
    dateClick: this.handleDateClick.bind(this),
    validRange: function(nowDate) {
      const aYearFromNow = new Date(nowDate);
      aYearFromNow.setFullYear(aYearFromNow.getFullYear() + 2);
      return {
        start: nowDate,
        end:  aYearFromNow
      };
    },
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
    { id: 1, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} },
    
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

  select(caretaker){
    this.selectedCaretaker = caretaker;
    // alert(this.selectedCaretaker.name);
  }

  showHide(){
    event.stopPropagation();
  }

}
