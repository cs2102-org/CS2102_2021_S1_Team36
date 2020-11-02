import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { BidService } from 'src/app/services/bid/bid.service';

@Component({
  selector: 'app-caretaker-bids',
  templateUrl: './caretaker-bids.component.html',
  styleUrls: ['./caretaker-bids.component.css']
})
export class CaretakerBidsComponent implements OnInit {
  showType = "";

  filterForm = new FormGroup({
    substr: new FormControl(''),
    start_date: new FormControl(''),
    end_date: new FormControl(''),
    pet_type: new FormControl(''),
    min: new FormControl(''),
    max: new FormControl(''),
  });

  bidForm = new FormGroup({
    owner_email: new FormControl(''),
    submission_time: new FormControl(''),
    pet_name: new FormControl(''),
    status: new FormControl('')
  });
  bids: any;

  constructor(private bidService: BidService) { }

  ngOnInit(): void {
    this.showAllBids();
  }

  showAllBids() {
    this.showType = "";
    this.bidService.getBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showPendingBids() {
    this.showType = "Pending";
    this.bidService.getPendingBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showDoneBids() {
    this.showType = "Done";
    this.bidService.getDoneBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  showRejectedBids() {
    this.showType = "Rejected";
    this.bidService.getRejectedBidsCaretaker().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  setBid(bid, status) {
    this.bidForm.controls['owner_email'].setValue(bid.owner_email);
    this.bidForm.controls['submission_time'].setValue(bid.submission_time);
    this.bidForm.controls['pet_name'].setValue(bid.pet_name);
    this.bidForm.controls['status'].setValue(status);
  }

  reloadAfterChangeBid(){
    if (this.showType === "")  {
      this.showAllBids();
    } else if (this.showType === "done") {
      this.showDoneBids();
    } else if (this.showType === "pending") {
      this.showPendingBids();
    } else {
      this.showRejectedBids();
    }
  }

  acceptBid(bid) {
    this.setBid(bid, true);
    this.bidService.postAcceptBid(this.bidForm.value).subscribe(msg => {
      if (msg) {
        this.reloadAfterChangeBid();
      }
    });
  }

  rejectBid(bid) {
    this.setBid(bid, false);
    this.bidService.postAcceptBid(this.bidForm.value).subscribe(msg => {
      if (msg) {
      this.reloadAfterChangeBid();
    }
    });
  }
  
  onSubmit(searchParam) {
    console.log('SENT');
    console.log(searchParam);
  }
}
