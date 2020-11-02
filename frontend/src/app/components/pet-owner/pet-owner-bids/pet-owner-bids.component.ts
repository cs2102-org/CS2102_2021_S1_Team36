import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { BidService } from 'src/app/services/bid/bid.service';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { Router } from '@angular/router';
import { MatDialog } from '@angular/material/dialog';
import { SubmitRatingComponent } from '../submit-rating/submit-rating.component';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

@Component({
  selector: 'app-pet-owner-bids',
  templateUrl: './pet-owner-bids.component.html',
  styleUrls: ['./pet-owner-bids.component.css']
})
export class PetOwnerBidsComponent implements OnInit {
  bids;
  showType = "";

  filterForm = new FormGroup({
    substr: new FormControl(''),
    start_date: new FormControl(''),
    end_date: new FormControl(''),
    pet_type: new FormControl(''),
    min: new FormControl(''),
    max: new FormControl(''),
  });

  currentDate = new Date();
  petTypes: any;

  constructor(private bidService: BidService, private router: Router, private dialog: MatDialog,
    private petOwnerService: PetownerService) { }

  ngOnInit(): void {
    this.showAllBids();
    this.getListOfPetTypes();
  }

  showAllBids() {
    this.showType = "";
    this.bidService.getBids().subscribe((bids) => {
      this.bids = bids;
    });
  }

  getListOfPetTypes() {
    this.petOwnerService.getGetListOfPetTypes().subscribe(petTypes => {
      this.petTypes = petTypes.map(elem => elem.species);
    });
  }

  checkPastDate(date) {
    return new Date(date) <= this.currentDate;
  }


  openCaretaker(bid) {
    const encrypted =  Base64.stringify(Utf8.parse(bid.caretaker_email));
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/caretaker/bid/' + encrypted])
    );
    window.open(url);
  }

  openSubmitRating(bid) {
    const dialogRef = this.dialog.open(SubmitRatingComponent, { data: {
      dataKey: bid
    }});
    dialogRef.afterClosed().subscribe(result => {
      if(result.data === 'Submit Success'){
        this.ngOnInit();
      }
    });
  }

  onSubmit() {
    console.log('SENT');
  }

  showPendingBids() {
    this.showType = "Pending";
    this.bidService.getPendingBids().subscribe((bids) => {
      this.bids = bids;
    });
  }

  showRejectedBids() {
    this.showType = "Rejected";
    this.bidService.getRejectedBids().subscribe((bids) => {
      this.bids = bids;
    });
  }

  showDoneBids() {
    this.showType = "Done";
    this.bidService.getDoneBids().subscribe((bids) => {
      this.bids = bids;
    });
  }
}
