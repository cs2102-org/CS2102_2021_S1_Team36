import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';

@Component({
  selector: 'app-caretaker-make-bid',
  templateUrl: './caretaker-make-bid.component.html',
  styleUrls: ['./caretaker-make-bid.component.css']
})
export class CaretakerMakeBidComponent implements OnInit {
  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

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

  constructor() { }

  ngOnInit(): void {
  }

  handleDateClick() {
    console.log("hi");
  }

  onSubmit(sd) {
    console.log("yes");
  }

}
