import { Component, Inject, OnInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

@Component({
  selector: 'app-detailed-pet',
  templateUrl: './detailed-pet.component.html',
  styleUrls: ['./detailed-pet.component.css']
})
export class DetailedPetComponent implements OnInit {
  pet;

  constructor(private dialogRef: MatDialogRef<DetailedPetComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private petOwnerService: PetownerService) { }

  ngOnInit(): void {
    this.getPetDetails();
  }

  getPetDetails() {
    this.petOwnerService.getPetDetails({pet_name: this.data.pet_name, owner_email: this.data.owner_email}).subscribe(detail => {
      this.pet = detail;
    });
  }

}
