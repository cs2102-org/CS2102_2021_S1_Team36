import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import dayGridPlugin from '@fullcalendar/daygrid';
import { BidService } from 'src/app/services/bid/bid.service';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import { BidDialogComponent } from '../../general/bid-dialog/bid-dialog.component';

@Component({
  selector: 'app-caretaker-summary-page',
  templateUrl: './caretaker-summary-page.component.html',
  styleUrls: ['./caretaker-summary-page.component.css']
})
export class CaretakerSummaryPageComponent implements OnInit {

  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    events: [],
    selectable: true,
    unselectAuto: false,
    select: this.selectDate.bind(this),
    datesSet: this.viewRenderer.bind(this),
    eventClick: this.openBidDialog.bind(this),
  };

  form = new FormGroup({
    start_date: new FormControl('', Validators.required),
    end_date: new FormControl('', Validators.required)
  });

  bids: any;
  caretakerType: string;
  currentStart;
  currentEnd;
  numOfWorkDaysInThatMonth = 0;
  earningsInThatMonth;

  constructor(private caretakerService: CaretakerService, private bidService: BidService
    , private dialog: MatDialog) { }

  ngOnInit(): void {
    this.getDates();
    this.checkFullTime();
  }

  ngAfterViewInit(): void {
    this.calendarComponent.getApi().render();
  }

  viewRenderer(dateInfo) {
    let aDate = new Date(dateInfo.start);
    aDate.setDate(aDate.getDate() + 1);
    this.currentStart = aDate.toISOString().slice(0,10);
    this.currentEnd = dateInfo.end.toISOString().slice(0,10);
    this.getEarningsForMonth();
  }

  reduceEarnings(total, add) {
    return total + Number(add.amount);
  }

  openBidDialog(selectionInfo) {
    this.dialog.open(BidDialogComponent, { data: {
      dataKey: this.bids[selectionInfo.event.id]
    }});
  }

  getEarningsForMonth() {
    const details = {start_date: this.currentStart, end_date: this.currentEnd};
    this.bidService.getCaretakerEarnings(details).subscribe(detail => {
      this.numOfWorkDaysInThatMonth = detail.length;
      this.earningsInThatMonth = detail.reduce(this.reduceEarnings, 0);
    });
  }

  checkFullTime() {
    this.caretakerType = localStorage.hasOwnProperty('is_fulltime') ? "Full Time" : "Part Time";
  }

  getDates() {
    this.caretakerService.getLeaveDates().subscribe(leaves => {
      leaves = leaves.map(leave => {leave.title="leave"; return leave;}); 

      this.bidService.getBidsCaretaker().subscribe((bids) => {
        let id = 1;
        const bidsUpdated = bids.map(bid => {bid.id = id++; return bid;});
        const copyBids =JSON.parse(JSON.stringify(bidsUpdated));
        this.bids = copyBids.reduce((accumulator, currentValue) => {
          accumulator[currentValue.id] = currentValue;
          return accumulator;
        }, {});

        const bidsMid = bidsUpdated.map(function(bid) {
          let aDate = new Date(bid.end);
          aDate.setDate(aDate.getDate() + 1);
          bid.end = aDate.toISOString().slice(0,10);
          
          bid.title = `Take care of ${bid.name}'s ${bid.pet_name}`;
          return bid;
        });    
        this.calendarOptions.events = bidsMid.concat(leaves);
      });
    });
  }

  selectDate(selectionInfo) {
    const startDate = selectionInfo.start;
    const endDate = selectionInfo.end;
    startDate.setDate(startDate.getDate() + 1);
    this.form.controls['start_date'].setValue(startDate.toISOString().slice(0,10));
    this.form.controls['end_date'].setValue(endDate.toISOString().slice(0,10));
  }

  onLeaveSubmit() {
    this.caretakerService.postNewLeave(this.form.value).subscribe(msg => {
      if (msg) {
        console.log("success");
      }
    });
  }
}
