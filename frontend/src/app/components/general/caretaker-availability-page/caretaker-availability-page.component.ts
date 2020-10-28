import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import { Subscription } from 'rxjs';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'

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
  caretakers: any[] = [];

  constructor(private caretakerService: CaretakerService, private router: Router) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.getActiveCaretakers();
  }

  getActiveCaretakers() {
    this.caretakersSubscription = this.caretakerService.getActiveCaretakers().subscribe((caretakers) => {
      let id = 1;
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
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
      this.caretakerService.getAvailFullTimeCareTaker(caretaker.email).subscribe((dates) => {
        dates.map(function(elem) { 
          let aDate = new Date(elem.end);
          aDate.setDate(aDate.getDate() + 1);
          elem.display = 'background';
          elem.groupId = 'No'; 
          elem.end = aDate.toISOString().slice(0,10);
          return elem;
        });
        this.calendarOptions.events = dates;
        this.selectedCaretaker = caretaker;  
      });
    }
  }

  openMakeBid() {
    const encrypted =  Base64.stringify(Utf8.parse(JSON.stringify(this.selectedCaretaker)));
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/bid-caretaker/' + encrypted])
    );
    window.open(url);
  }

  showHide(caretaker){
    event.stopPropagation();
    if (!caretaker.showTakeCare) {
      this.caretakerService.getCareTakerPrice(caretaker.email).subscribe((prices) => {
        caretaker.takesCare = prices;
        caretaker.showTakeCare = true;
      });
    } else {
      caretaker.showTakeCare = false;
      caretaker.takesCare = [];
    }
  }

}
