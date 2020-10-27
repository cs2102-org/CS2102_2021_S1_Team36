import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import { Subscription } from 'rxjs';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';

@Component({
  selector: 'app-caretaker-availability-page',
  templateUrl: './caretaker-availability-page.component.html',
  styleUrls: ['./caretaker-availability-page.component.css']
})
export class CaretakerAvailabilityPageComponent implements OnInit {
  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  selectedCaretaker;
  placeholderDate: String;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    height: 450,
    validRange: function(nowDate) {
      const aYearFromNow = new Date(nowDate);
      aYearFromNow.setFullYear(aYearFromNow.getFullYear() + 2);
      return {
        start: nowDate,
        end:  aYearFromNow
      };
    },
    events: [],
    eventBackgroundColor: 'grey',
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

  caretakersSubscription: Subscription;
  caretakers: any[] = [
    { id: 1, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {} },
    { id: 2, name: 'Dr Nice', rating: 5, type: "Full Time", takesCare: {'Dogs': 10, 'Cat': 20} }
  ];

  constructor(private caretakerService: CaretakerService) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.getActiveCaretakers();
  }

  getActiveCaretakers() {
    this.caretakersSubscription = this.caretakerService.getActiveCaretakers().subscribe((caretakers) => {
      let id = 1;
      caretakers.map(elem => {elem.id = id++;});
      this.caretakers = caretakers;
    });
  }

  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }

  select(caretaker){
    if (caretaker.type == "Part Time") {
      this.caretakerService.getAvailPartTimeCareTaker(caretaker.email).subscribe((dates) => {
        dates.push({"date": this.placeholderDate});
        dates.map(elem => {elem.display = 'inverse-background'; elem.groupId= 'yes';});
        this.calendarOptions.events = dates;
        this.selectedCaretaker = caretaker;  
      });
    } else {
      this.calendarOptions.events = [];
    }
  }

  showHide(caretaker){
    event.stopPropagation();
    caretaker.takesCare['random'] = 30;
  }

}
