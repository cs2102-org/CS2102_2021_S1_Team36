import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import { PcsadminService } from 'src/app/services/pcsadmin/pcsadmin.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';
import { FormNewAdminComponent } from '../form-new-admin/form-new-admin.component';
import { FormNewCaretakerComponent } from '../form-new-caretaker/form-new-caretaker.component';
import { FormNewPetTypeComponent } from '../form-new-pet-type/form-new-pet-type.component';
import Base64 from 'crypto-js/enc-base64';
import Utf8 from 'crypto-js/enc-utf8'
import { Router } from '@angular/router';

@Component({
  selector: 'app-manage-users',
  templateUrl: './manage-users.component.html',
  styleUrls: ['./manage-users.component.css']
})
export class ManageUsersComponent implements OnInit {
  showType = "Admins";
  things;

  constructor(private caretakerService: CaretakerService, private dialog: MatDialog,
    private pcsAdminService: PcsadminService,
    private petOwnerService: PetownerService,
    private router: Router) { }

  ngOnInit(): void {
    this.getAllAdmins();
  }

  getAllCaretakers() {
    this.caretakerService.getAllCaretakers().subscribe(caretakers => {
      this.showType = "Caretakers";
      this.things = caretakers;
    });
  }

  getAllAdmins() {
    this.pcsAdminService.getAdminList().subscribe(admins => {
      this.showType = "Admins";
      this.things = admins;
    });
  }

  getAllPetTypes() {
    this.pcsAdminService.getListOfPetTypes().subscribe(petTypes => {
      this.showType = "Pet Types";
      this.things = petTypes;
    });
  }

   getAllPetOwners() {
    this.petOwnerService.getAllPetOwners().subscribe(po => {
      this.showType = "Pet Owners";
      this.things = po;
    });
  }

  openMakeBid(selectedCaretaker) {
    const encrypted =  Base64.stringify(Utf8.parse(selectedCaretaker.email));
    const url = this.router.serializeUrl(
      this.router.createUrlTree(['/caretaker/bid/' + encrypted])
    );
    window.open(url);
  }


  openNewCaretakerForm() {
    const ref = this.dialog.open(FormNewCaretakerComponent);
    // ref.disableClose = true;
  }

  openNewAdminForm() {
    const ref = this.dialog.open(FormNewAdminComponent);
    // ref.disableClose = true;
  }

  openNewTypeForm() {
    const ref = this.dialog.open(FormNewPetTypeComponent);
    // ref.disableClose = true;
  }
}
