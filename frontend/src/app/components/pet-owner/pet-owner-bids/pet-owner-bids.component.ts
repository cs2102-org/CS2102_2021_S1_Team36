import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { BidService } from 'src/app/services/bid/bid.service';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { Router } from '@angular/router';
import { MatDialog } from '@angular/material/dialog';
import { SubmitRatingComponent } from '../submit-rating/submit-rating.component';

@Component({
  selector: 'app-pet-owner-bids',
  templateUrl: './pet-owner-bids.component.html',
  styleUrls: ['./pet-owner-bids.component.css']
})
export class PetOwnerBidsComponent implements OnInit {
  bids;

  filterForm = new FormGroup({
    substr: new FormControl(''),
    start_date: new FormControl(''),
    end_date: new FormControl(''),
    pet_type: new FormControl(''),
    min: new FormControl(''),
    max: new FormControl(''),
  });

  constructor(private bidService: BidService, private router: Router, private dialog: MatDialog) { }

  ngOnInit(): void {
    this.showAllBids();
  }

  showAllBids() {
    this.bidService.getBids().subscribe((bids) => {
      console.log(bids);
      this.bids = bids;
    });
  }

  openCaretaker(bid) {
    const encrypted =  Base64.stringify(Utf8.parse(bid.caretaker_email));
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/caretaker/bid/' + encrypted])
    );
    window.open(url);
  }

  openSubmitRating(bid) {
    this.dialog.open(SubmitRatingComponent, { data: {
    dataKey: bid
  }});
  }

  onSubmit() {
    console.log('SENT');
  }
}
