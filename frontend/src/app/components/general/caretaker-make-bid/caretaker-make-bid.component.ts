import { Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormControl, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { CalendarOptions, FullCalendarComponent, isDateSpansEqual, sliceEventStore } from '@fullcalendar/angular';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { AuthService } from 'src/app/services/auth/auth.service';
import { BidService } from 'src/app/services/bid/bid.service';
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

  bidSuccess = false;
  isLogged = false;
  pets;
  dates;
  caretaker;
  takesCare;
  placeholderDate: String;
  currentMinPrice: number = 0;
  numberOfBidDays: number = 0;
  totalAmount = 0;

  bidForm = new FormGroup({
    start_date: new FormControl('', Validators.required),
    end_date: new FormControl('', Validators.required),
    pet_name: new FormControl('', Validators.required),
    submission_time: new FormControl(''),
    caretaker_email: new FormControl(''),
    payment_type: new FormControl('', Validators.required),
    transfer_type: new FormControl('', Validators.required),
    amount_bidded: new FormControl('', [Validators.required, (control: AbstractControl) => Validators.min(this.currentMinPrice)(control)]),
  });
  reviews: any;

  constructor(private caretakerService: CaretakerService, 
    private route: ActivatedRoute,
    private petOwnerService: PetownerService,
    private authService: AuthService,
    private bidService: BidService) { }

  ngOnInit(): void {
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.findCaretaker();
    this.petNameFormChangeSubscribe();
    this.formResets();
  }

  formResets() {
    this.bidForm.valueChanges.subscribe(val => {
      this.bidSuccess = false;
    });
  }

  petNameFormChangeSubscribe() {
    this.bidForm.get("pet_name").valueChanges.subscribe(selectedValue  => {
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
      this.getReviews();
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
        this.dates = dates.map(a => a.date);
        dates.push({"date": this.placeholderDate});
        dates.map(elem => {elem.display = 'background'; elem.groupId= 'No';});
        this.calendarOptions.events = dates;
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
        if (this.dates.indexOf(date) >= 0) {
          return false;
        }
      }
    }
    return true;
  }

  getPetOwnerPets() {
    this.petOwnerService.getPetOwnerPetsWithCaretaker(this.caretaker.email).subscribe((pets) => {
      this.pets = pets.reduce((accumulator, currentValue) => {
        accumulator[currentValue.pet_name] = currentValue.species;
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
    bidForm.controls['submission_time'].setValue(new Date());
    bidForm.controls['caretaker_email'].setValue(this.caretaker.email);
    bidForm.controls['amount_bidded'].setValue(bidForm.get('amount_bidded').value / this.numberOfBidDays);
    this.bidService.postBid(bidForm.value).subscribe(status => {
      if (status) {
        this.bidForm.reset();
        this.bidSuccess=true;
      }
    });
  }

  selectBidDate(selectionInfo) {
    const startDate = selectionInfo.start;
    const endDate = selectionInfo.end;
    this.numberOfBidDays = (endDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24); 
    startDate.setDate(startDate.getDate() + 1);
    this.bidForm.controls['start_date'].setValue(startDate.toISOString().slice(0,10));
    this.bidForm.controls['end_date'].setValue(endDate.toISOString().slice(0,10));
    const price = this.pets[this.bidForm.get('pet_name').value];
      for (let pet of this.takesCare) {
        if (pet.species == price) {
          this.currentMinPrice = parseFloat(pet.daily_price) * this.numberOfBidDays;
        }
      }
  }

  getReviews() {
    this.caretakerService.getCaretakerReviews(this.caretaker.email).subscribe(reviews => {
      this.reviews = reviews;
    });
  }


}
