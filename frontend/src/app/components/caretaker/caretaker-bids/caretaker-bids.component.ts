import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { BidService } from 'src/app/services/bid/bid.service';

@Component({
  selector: 'app-caretaker-bids',
  templateUrl: './caretaker-bids.component.html',
  styleUrls: ['./caretaker-bids.component.css']
})
export class CaretakerBidsComponent implements OnInit {
  filterForm = new FormGroup({
    substr: new FormControl(''),
    start_date: new FormControl(''),
    end_date: new FormControl(''),
    pet_type: new FormControl(''),
    min: new FormControl(''),
    max: new FormControl(''),
  });
  bids: any;

  constructor(private bidService: BidService) { }

  ngOnInit(): void {
    this.showAllBids();
  }

  showAllBids() {
    this.bidService.getBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showPendingBids() {
    this.bidService.getPendingBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showDoneBids() {
    this.bidService.getDoneBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showRejectedBids() {
    this.bidService.getRejectedBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }
  
  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }
}
