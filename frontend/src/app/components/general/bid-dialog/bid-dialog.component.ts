import { Component, Inject, OnInit } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

@Component({
  selector: 'app-bid-dialog',
  templateUrl: './bid-dialog.component.html',
  styleUrls: ['./bid-dialog.component.css']
})
export class BidDialogComponent implements OnInit {

  bid;
  petDetails;
  hide = true;

  constructor(private dialogRef: MatDialogRef<BidDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
    private petOwnerService: PetownerService) { }

  ngOnInit(): void {
    this.bid = this.changeTransferType(this.data.dataKey);
    console.log(this.bid);
  }

  changeTransferType(bid) {
    if (bid.transfer_type == 1) {
      bid.transfer = "Pet Owner deliver";
    } else if (bid.transfer_type == 2) {
      bid.transfer = "Caretaker pick up";
    } else {
      bid.transfer= "Transfer through the physical building of PCS";
    }
    return bid;
  }

  showPetDetails() {
    this.petOwnerService.getPetDetails({pet_name: this.bid.pet_name, owner_email: this.bid.owner_email}).subscribe(detail => {
      console.log(detail);
      this.hide = false;
      this.petDetails = detail;
    })
  }

}
