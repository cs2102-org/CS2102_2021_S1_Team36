import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { CalendarOptions, FullCalendarComponent, isDateSpansEqual, sliceEventStore } from '@fullcalendar/angular';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
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
  placeholderDate: String;

  bidForm = new FormGroup({
    dateFrom: new FormControl(''),
    dateTo: new FormControl(''),
    petType: new FormControl(''),
  });

  constructor(private caretakerService: CaretakerService, 
    private route: ActivatedRoute,
    private petOwnerService: PetownerService) { }

  ngOnInit(): void {
    this.checkIsLogged();
    let aDate = new Date();
    aDate.setDate(aDate.getDate() - 1);
    this.placeholderDate = aDate.toISOString().slice(0,10);
    this.findCaretaker();
  }

  findCaretaker() {
    const caretakerHashed = this.route.snapshot.paramMap.get("caretaker");
    this.caretaker = JSON.parse(Utf8.stringify(Base64.parse(caretakerHashed)));
    this.loadCalendar();
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
      this.calendarOptions.events = [];
    }
  }

  checkIsLogged() {
    if (localStorage.getItem('accessToken') != null) {
      this.isLogged = true;
    }
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
    for (let date of dateArray) {
      if (this.dates.indexOf(date) < 0) {
        return false;
      }
    }
    return true;
  }

  getPetOwnerPets() {
    this.petOwnerService.getPetOwnerPets().subscribe((pets) => {
      this.pets = pets;
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

  onSubmit(sd) {
    console.log("yes");
  }

  selectBidDate(selectionInfo) {
    const startDate = selectionInfo.start;
    startDate.setDate(startDate.getDate() + 1);
    this.bidForm.controls['dateFrom'].setValue(startDate.toISOString().slice(0,10));
    this.bidForm.controls['dateTo'].setValue(selectionInfo.end.toISOString().slice(0,10));
    // console.log(this.bidForm);
  }

}
