import { Component, Inject, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { PcsadminService } from 'src/app/services/pcsadmin/pcsadmin.service';

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

  constructor(private dialogRef: MatDialogRef<UpdateBasePriceComponent>, @Inject(MAT_DIALOG_DATA) public data: any,
  private pcsAdminService: PcsadminService) { }

  ngOnInit(): void {
    this.species = this.data['pet_type']['species'];
    this.typeForm.controls['species'].setValue(this.species);
  }

  onSubmitType(details) {
    this.pcsAdminService.putPetType(details).subscribe(msg => {
      if (msg) {
        this.dialogRef.close('(' + this.species + ') base price updated as $' + details.base_price);
      }
    })
  }
}
