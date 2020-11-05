import { Component, Inject, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { BidService } from 'src/app/services/bid/bid.service';

@Component({
  selector: 'app-submit-rating',
  templateUrl: './submit-rating.component.html',
  styleUrls: ['./submit-rating.component.css']
})
export class SubmitRatingComponent implements OnInit {

  error = "Some error occured";
  hasError = false;

  ratingForm = new FormGroup({
    caretaker_email: new FormControl(''),
    rating: new FormControl('', Validators.required),
    review: new FormControl(''),
    pet_name: new FormControl(''),
    submission_time: new FormControl('')
  });

  name = "";
  bid;

  constructor(private dialogRef: MatDialogRef<SubmitRatingComponent>, @Inject(MAT_DIALOG_DATA) public data: any,
    private bidService: BidService) { }

  ngOnInit(): void {
    this.bid = this.data.dataKey;
    this.name = this.bid.name;
    this.ratingForm.controls['caretaker_email'].setValue(this.bid['caretaker_email']);
    this.ratingForm.controls['pet_name'].setValue(this.bid['pet_name']);
    this.ratingForm.controls['submission_time'].setValue(this.bid['submission_time']);
  }

  onSubmit() {
    this.bidService.putBidRating(this.ratingForm.value).subscribe(result => {
      if (result.message.indexOf('Updated') >= 0) {
        this.hasError = false;
        this.dialogRef.close({data: "Submit Success"});
      } else {
        this.hasError = true;
      }
    });
  }
}
