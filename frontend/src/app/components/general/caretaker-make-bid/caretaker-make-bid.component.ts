import { Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormControl, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { CalendarOptions, FullCalendarComponent, isDateSpansEqual, sliceEventStore } from '@fullcalendar/angular';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { AuthService } from 'src/app/services/auth/auth.service';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

@Component({
  selector: 'app-caretaker-make-bid',
  templateUrl: './caretaker-make-bid.component.html',
  styleUrls: ['./caretaker-make-bid.component.css']
})
export class CaretakerMakeBidComponent implements OnInit {
  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    validRange: function(nowDate) {
      const aYearFromNow = new Date(nowDate);
      aYearFromNow.setFullYear(aYearFromNow.getFullYear() + 2);
      return {
        start: nowDate,
        end:  aYearFromNow
      };
    },
    selectable: true,
    unselectAuto: false,
    height: 450,
    select: this.selectBidDate.bind(this),
    events: [],
    eventBackgroundColor: 'grey',
    selectAllow: this.selectAllowable.bind(this)
  };

  isLogged = false;
  pets;
  dates;
  caretaker;
  takesCare;
  placeholderDate: String;
  currentMinPrice: number = 0;
  numberOfBidDays: number = 0;

  bidForm = new FormGroup({
    dateFrom: new FormControl('', Validators.required),
    dateTo: new FormControl('', Validators.required),
    petName: new FormControl('', Validators.required),
    submissionTime: new FormControl(''),
    caretakerEmail: new FormControl(''),
    paymentType: new FormControl('', Validators.required),
    transferType: new FormControl('', Validators.required),
    bidPrice: new FormControl('', [Validators.required, (control: AbstractControl) => Validators.min(this.currentMinPrice)(control)]),
  });

  constructor(private caretakerService: CaretakerService, 
    private route: ActivatedRoute,
    private petOwnerService: PetownerService,
    private authService: AuthService) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.findCaretaker();
    this.petNameFormChangeSubscribe();
  }

  petNameFormChangeSubscribe() {
    this.bidForm.get("petName").valueChanges.subscribe(selectedValue  => {
      const price = this.pets[selectedValue];
      for (let pet of this.takesCare) {
        if (pet.species == price) {
          this.currentMinPrice = parseFloat(pet.daily_price) * this.numberOfBidDays;
        }
      }
    });
  }

  findCaretaker() {
    const caretakerHashed = this.route.snapshot.paramMap.get("caretaker");
    const email = Utf8.stringify(Base64.parse(caretakerHashed));
    this.getCaretaker(email);
  }

  getCaretaker(email) {
    this.caretakerService.getCareTakerDetails(email).subscribe((caretaker) => {
      this.caretaker = caretaker[0];
      this.checkIsLogged();
      this.loadCalendar();
      this.findTakeCares();
    });
  }

  findTakeCares() {
    this.caretakerService.getCareTakerPrice(this.caretaker.email).subscribe((prices) => {
      this.takesCare = prices;
    });
  }

  loadCalendar() {
    if (this.caretaker.type == "Part Time") {
      this.caretakerService.getAvailPartTimeCareTaker(this.caretaker.email).subscribe((dates) => {
        this.dates = dates.map(a => a.date);
        dates.push({"date": this.placeholderDate});
        dates.map(elem => {elem.display = 'inverse-background'; elem.groupId= 'yes';});
        this.calendarOptions.events = dates;
      });
    } else {
      this.caretakerService.getAvailFullTimeCareTaker(this.caretaker.email).subscribe((dates) => {
        dates.map(function(date) { 
          let aDate = new Date(date.end);
          aDate.setDate(aDate.getDate() + 1);
          date.display = 'background';
          date.groupId = 'No'; 
          date.end = aDate.toISOString().slice(0,10);
          return date;
        });
        this.calendarOptions.events = dates; 
        this.dates = dates.map(a => [a.start, a.end]);
      });
    }
  }

  checkIsLogged() {
    if (localStorage.getItem('accessToken') != null) {
      this.isLogged = true;
      this.getPetOwnerPets();
    }
    this.authService.loginNotiService
      .subscribe(message => {
        if (message == "Login success") {
          this.isLogged=true;
          this.getPetOwnerPets();
        } else {
          this.isLogged=false;
        }
      });
  }

  selectAllowable(selectInfo) {
    var dateArray = new Array();
    var currentDate = selectInfo.start;
    currentDate.setDate(currentDate.getDate() + 1);
    var endDate = selectInfo.end;
    endDate.setDate(endDate.getDate() + 1);
    while (currentDate < endDate) {
      dateArray.push(new Date (currentDate));
      var result = new Date(currentDate);
      result.setDate(currentDate.getDate() + 1);
      currentDate = result;
    }
    dateArray = dateArray.map(a => a.toISOString().slice(0,10));
    if (this.caretaker.type == "Part Time") {
      for (let date of dateArray) {
        if (this.dates.indexOf(date) < 0) {
          return false;
        }
      }
    } else {
      for (let date of dateArray) {
        const checkDate = new Date(date)
        for (let dateRange of this.dates) {
          const startDate = new Date(dateRange[0]);
          const endDate = new Date(dateRange[1]);
          if (startDate <= checkDate && checkDate < endDate) {
            return false;
          }
        }
      }
    }
    return true;
  }

  getPetOwnerPets() {
    this.petOwnerService.getPetOwnerPetsWithCaretaker(this.caretaker.email).subscribe((pets) => {
      this.pets = pets.reduce((accumulator, currentValue) => {
        accumulator[currentValue.pet_name + '(' + currentValue.species + ')'] = currentValue.species;
        return accumulator;
      }, {});
    });
  }

  getDates(startDate, stopDate) {
    var dateArray = new Array();
    var currentDate = startDate;
    while (currentDate <= stopDate) {
        dateArray.push(new Date (currentDate));
        currentDate = currentDate.addDays(1);
    }
    return dateArray;
  }

  onSubmit(bidForm) {
    bidForm.controls['submissionTime'].setValue(new Date());
    bidForm.controls['caretakerEmail'].setValue(this.caretaker.email);
    console.log(bidForm.value);
  }

  selectBidDate(selectionInfo) {
    const startDate = selectionInfo.start;
    const endDate = selectionInfo.end;
    this.numberOfBidDays = (endDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24); 
    startDate.setDate(startDate.getDate() + 1);
    this.bidForm.controls['dateFrom'].setValue(startDate.toISOString().slice(0,10));
    this.bidForm.controls['dateTo'].setValue(endDate.toISOString().slice(0,10));
    const price = this.pets[this.bidForm.get('petName').value];
      for (let pet of this.takesCare) {
        if (pet.species == price) {
          this.currentMinPrice = parseFloat(pet.daily_price) * this.numberOfBidDays;
        }
      }
  }

}
