import { Component, Inject, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';

@Component({
  selector: 'app-update-base-price',
  templateUrl: './update-base-price.component.html',
  styleUrls: ['./update-base-price.component.css']
})
export class UpdateBasePriceComponent implements OnInit {
  species;
  typeForm = new FormGroup({
    species: new FormControl(''),
    base_price: new FormControl('', Validators.required)
  });

  constructor(private dialogRef: MatDialogRef<UpdateBasePriceComponent>, @Inject(MAT_DIALOG_DATA) public data: any) { }

  ngOnInit(): void {
    this.species = this.data['pet_type']['species'];
    console.log(this.data['pet_type']);
  }

  onSubmitType(details) {
  
  }
}
