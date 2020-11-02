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
      this.bids = bids.map(this.changeTransferType)
        .map(this.changePaymentType)
        .map(this.changeConfirmation)
        .map(this.changePaid);
    });
  }

  showPendingBids() {
    this.showType = "Pending";
    this.bidService.getPendingBidsCaretaker().subscribe((bids) => {
      this.bids = bids.map(this.changeTransferType)
        .map(this.changePaymentType)
        .map(this.changeConfirmation)
        .map(this.changePaid);
    });
  }

  showDoneBids() {
    this.showType = "Done";
    this.bidService.getDoneBidsCaretaker().subscribe((bids) => {
      this.bids = bids.map(this.changeTransferType)
        .map(this.changePaymentType)
        .map(this.changeConfirmation)
        .map(this.changePaid);
    });
  }

  showRejectedBids() {
    this.showType = "Rejected";
    this.bidService.getRejectedBidsCaretaker().subscribe((bids) => {
      this.bids = bids.map(this.changeTransferType)
        .map(this.changePaymentType)
        .map(this.changeConfirmation)
        .map(this.changePaid);
    });
  }

  setBid(bid, status) {
    this.bidForm.controls['owner_email'].setValue(bid.owner_email);
    this.bidForm.controls['submission_time'].setValue(bid.submission_time);
    this.bidForm.controls['pet_name'].setValue(bid.pet_name);
    this.bidForm.controls['status'].setValue(status);
  }

  setBidPaid(bid) {
    this.bidForm.controls['owner_email'].setValue(bid.owner_email);
    this.bidForm.controls['submission_time'].setValue(bid.submission_time);
    this.bidForm.controls['pet_name'].setValue(bid.pet_name);
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

  changeTransferType(bid) {
    if (bid.transfer_type == 1) {
      bid.transfer = "Pet Owner deliver";
    } else if (bid.transfer_type == 2) {
      bid.transfer = "Caretaker pick up";
    } else {
      bid.transfer= "Transfer by PCS Building";
    }
    return bid;
  }

  changePaymentType(bid) {
    if (bid.payment_type == 1) {
      bid.payment_type = "Cash";
    } else {
      bid.payment_type= "Credit Card";
    }
    return bid;
  }

  changePaid(bid) {
    if (bid.is_paid) {
      bid.is_paid = "Paid";
    } else {
      bid.is_paid = "Not Paid";
    }
    return bid;
  }

  changeConfirmation(bid) {
    if (bid.is_confirmed) {
      bid.is_confirmed  = "Confirmed";
    } else {
      bid.is_confirmed = "Not Confirmed";
    }
    return bid;
  }

  postPaid(bid) {
    this.setBidPaid(bid);
    this.bidService.postPaidBid(this.bidForm.value).subscribe(msg => {
      this.reloadAfterChangeBid();
    });
  }
}
