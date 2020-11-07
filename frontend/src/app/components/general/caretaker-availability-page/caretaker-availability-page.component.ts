import { Component, OnInit, ViewChild } from '@angular/core';
import { FormGroup, FormControl, AbstractControl, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import { Subscription } from 'rxjs';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { AuthService } from 'src/app/services/auth/auth.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

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
  petTypes;

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
    min: new FormControl('', Validators.min(0)),
    max: new FormControl(''),
    is_fulltime: new FormControl(''),
    rating: new FormControl('', [Validators.min(0), Validators.max(5)])
  });

  caretakers: any[] = [];
  isLogged: boolean = false;

  constructor(private caretakerService: CaretakerService, private router: Router,
    private authService: AuthService, private petOwnerService: PetownerService) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.getActiveCaretakers();
    this.checkIsLogged();
    this.getListOfPetTypes();
  }

  getActiveCaretakers() {
    this.caretakerService.getActiveCaretakers().subscribe((caretakers) => {
      let id = 1;
      this.typeOfList = "";
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
      this.caretakers = caretakers;
    });
  }

  getListOfPetTypes() {
    this.petOwnerService.getListOfPetTypes().subscribe(petTypes => {
      this.petTypes = petTypes.map(elem => elem.species);
    });
  }

  showRecommendedCaretakers() {
    this.caretakerService.getRecommendedCaretakers().subscribe((caretakers) => {
      this.typeOfList = "Recommended";
      let id = 1;
      caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
      this.caretakers = caretakers;
    });
  }

  showTransactedCaretakers() {
    this.caretakerService.getTransactedCaretakers().subscribe((caretakers) => {
      console.log(caretakers);
      this.typeOfList = "Previously Transacted";
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
    this.checkFormControl("is_fulltime");

    if (this.typeOfList === "") {
      this.caretakerService.getFilteredActiveCaretakers(this.filterForm.value).subscribe((caretakers) => {
        let id = 1;
        caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
        this.caretakers = caretakers;
      });
    } else if (this.typeOfList === "Previously Transacted") {
      this.caretakerService.getFilteredTransactedCaretakers(this.filterForm.value).subscribe((caretakers) => {
        let id = 1;
        caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
        this.caretakers = caretakers;
      }); 
    } else {
      this.caretakerService.getFilteredRecommendedCaretakers(this.filterForm.value).subscribe((caretakers) => {
        let id = 1;
        caretakers.map(elem => {elem.id = id++; elem.showTakeCare = false;});
        this.caretakers = caretakers;
      }); 
    }
  }

  checkFormControl(name) {
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
          elem.display = 'background';
          elem.groupId = 'No'; 
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
    this.router.navigateByUrl(url);
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
