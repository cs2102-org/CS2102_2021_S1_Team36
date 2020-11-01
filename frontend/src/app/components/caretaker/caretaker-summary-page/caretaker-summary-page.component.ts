import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import dayGridPlugin from '@fullcalendar/daygrid';
import { BidService } from 'src/app/services/bid/bid.service';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';

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
    select: this.selectLeaveDate.bind(this)
  };

  leaveForm = new FormGroup({
    start_date: new FormControl('', Validators.required),
    end_date: new FormControl('', Validators.required)
  });
  bids: any;


  constructor(private caretakerService: CaretakerService, private bidService: BidService) { }

  ngOnInit(): void {
    this.getDates();
  }

  ngAfterViewInit(): void {
    this.calendarComponent.getApi().render();
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

  selectLeaveDate(selectionInfo) {
    const startDate = selectionInfo.start;
    const endDate = selectionInfo.end;
    startDate.setDate(startDate.getDate() + 1);
    this.leaveForm.controls['start_date'].setValue(startDate.toISOString().slice(0,10));
    this.leaveForm.controls['end_date'].setValue(endDate.toISOString().slice(0,10));
  }

  onSubmit() {
    this.caretakerService.postNewLeave(this.leaveForm.value).subscribe(msg => {
      if (msg) {
        console.log("success");
      }
    });
  }
}
