import { Component, OnInit, ViewChild } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { Title } from '@angular/platform-browser';
import { CalendarOptions, FullCalendarComponent } from '@fullcalendar/angular';
import { cpuUsage } from 'process';
import { BidService } from 'src/app/services/bid/bid.service';
import { BidDialogComponent } from '../../general/bid-dialog/bid-dialog.component';

@Component({
  selector: 'app-pet-owner-summary',
  templateUrl: './pet-owner-summary.component.html',
  styleUrls: ['./pet-owner-summary.component.css']
})
export class PetOwnerSummaryComponent implements OnInit {

  @ViewChild('calendar') calendarComponent: FullCalendarComponent;

  calendarOptions: CalendarOptions = {
    initialView: 'dayGridMonth',
    events: [],
    eventBackgroundColor: 'lightblue',
    eventTextColor: 'black',
    eventClick: this.openBidDialog.bind(this),
  };

  bids;

  constructor(private bidService: BidService, private dialog: MatDialog,
    private titleService: Title) { 
    this.titleService.setTitle('Pet Owner');
  }

  ngOnInit(): void {
    this.getEventsOnCalendar();
  }

  ngAfterViewInit(): void {
    this.calendarComponent.getApi().render();
  }
  
  openBidDialog(selectionInfo) {
    this.dialog.open(BidDialogComponent, { data: {
      dataKey: this.bids[selectionInfo.event.id],
      type: "Caretaker: "
    }});
  }

  getEventsOnCalendar() {
    this.bidService.getBids().subscribe(bids => {
      let id = 1;
      const bidsUpdated = bids.map(bid => {bid.id = id++; return bid;});
      const copyBids =JSON.parse(JSON.stringify(bidsUpdated));
      this.bids = copyBids.reduce((accumulator, currentValue) => {
        accumulator[currentValue.id] = currentValue;
        return accumulator;
      }, {});
      this.calendarOptions.events = bidsUpdated.map(function(bid) {
        let aDate = new Date(bid.end);
        aDate.setDate(aDate.getDate() + 1);
        bid.end = aDate.toISOString().slice(0,10);
        
        bid.title = `${bid.pet_name} taken care by ${bid.name}`;
        return bid;
      });      
    })
  }
}
