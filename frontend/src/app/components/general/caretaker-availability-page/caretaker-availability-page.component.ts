import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { Router } from '@angular/router';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import { Subscription } from 'rxjs';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { AuthService } from 'src/app/services/auth/auth.service';

@Component({
  selector: 'app-caretaker-availability-page',
  templateUrl: './caretaker-availability-page.component.html',
  styleUrls: ['./caretaker-availability-page.component.css']
})
export class CaretakerAvailabilityPageComponent implements OnInit {
  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  selectedCaretaker;
  placeholderDate: String;
  typeOfList = "";

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
    substr: new FormControl(''),
    start_date: new FormControl(''),
    end_date: new FormControl(''),
    pet_type: new FormControl(''),
    min: new FormControl(''),
    max: new FormControl(''),
    rating: new FormControl('')
  });

  caretakers: any[] = [];
  isLogged: boolean = false;

  constructor(private caretakerService: CaretakerService, private router: Router,
    private authService: AuthService) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.getActiveCaretakers();
    this.checkIsLogged();
  }

  getActiveCaretakers() {
    this.caretakerService.getActiveCaretakers().subscribe((caretakers) => {
      let id = 1;
      this.typeOfList = "";
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
      this.caretakers = caretakers;
    });
  }

  showRecommendedCaretakers() {
    this.caretakerService.getRecommendedCaretakers().subscribe((caretakers) => {
      console.log(caretakers);
      this.typeOfList = "Recommended";
      let id = 1;
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
      this.caretakers = caretakers;
    });
  }

  onSubmit() {
    this.checkFormControl("start_date");
    this.checkFormControl("end_date");
    this.checkFormControl("rating");
    this.checkFormControl("pet_type");
    this.checkFormControl("min");
    this.checkFormControl("max");
    this.checkFormControl("substr");
    console.log(this.filterForm.value);
    this.caretakerService.getFilteredActiveCaretakers(this.filterForm.value).subscribe((caretakers) => {
      console.log(caretakers);
      let id = 1;
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
      this.caretakers = caretakers;
    });
  }

  checkFormControl(name) {
    console.log(name);
    if (this.filterForm.get(name).value === "") {
      this.filterForm.controls[name].setValue(null);
    }
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

  checkIsLogged() {
    if (localStorage.getItem('accessToken') != null) {
      this.isLogged = true;
    }
    this.authService.loginNotiService
      .subscribe(message => {
        if (message == "Login success") {
          this.isLogged=true;
        } else {
          this.isLogged=false;
        }
      });
  }

  openMakeBid() {
    const encrypted =  Base64.stringify(Utf8.parse(this.selectedCaretaker.email));
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/caretaker/bid/' + encrypted])
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
