import { Component, Inject, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

@Component({
  selector: 'app-submit-rating',
  templateUrl: './submit-rating.component.html',
  styleUrls: ['./submit-rating.component.css']
})
export class SubmitRatingComponent implements OnInit {

  ratingForm = new FormGroup({
    rating: new FormControl('', Validators.required)
  });

  name = "";
  bid;

  constructor(private dialogRef: MatDialogRef<SubmitRatingComponent>, @Inject(MAT_DIALOG_DATA) public data: any) { }

  ngOnInit(): void {
    this.bid = this.data.dataKey;
    this.name = this.bid.name;
  }

  onSubmit(){}
}
