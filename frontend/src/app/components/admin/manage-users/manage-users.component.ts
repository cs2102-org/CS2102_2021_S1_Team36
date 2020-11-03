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
import { DetailedPetComponent } from '../detailed-pet/detailed-pet.component';

@Component({
  selector: 'app-manage-users',
  templateUrl: './manage-users.component.html',
  styleUrls: ['./manage-users.component.css']
})
export class ManageUsersComponent implements OnInit {
  showType = "Admins";
  things;
  msg = '';
  searchValue: string;

  constructor(private caretakerService: CaretakerService, private dialog: MatDialog,
    private pcsAdminService: PcsadminService,
    private petOwnerService: PetownerService,
    private router: Router) { }

  ngOnInit(): void {
    this.getAllAdmins();
  }

  getAllCaretakers() {
    const start = new Date('1000-01-01');
    const end = new Date('3000-01-01');
    this.pcsAdminService.getAllCaretakers({start_date: start, end_date: end}).subscribe(caretakers => {
      this.showType = "Caretakers";
      this.msg = '';
      this.things = caretakers.map(c => {c.is_fulltime = c.is_fulltime ? "Full Time" : "Part Time"; return c;});
    });
  }

  getAllAdmins() {
    this.pcsAdminService.getAdminList().subscribe(admins => {
      this.showType = "Admins";
      this.msg = '';
      this.things = admins;
    });
  }

  getAllPetTypes() {
    this.pcsAdminService.getListOfPetTypes().subscribe(petTypes => {
      this.showType = "Pet Types";
      this.msg = '';
      this.things = petTypes;
    });
  }

   getAllPetOwners() {
    this.petOwnerService.getAllPetOwners().subscribe(po => {
      this.showType = "Pet Owners";
      this.msg = '';
      this.things = po.map(po => {po.show = false; return po;});
    });
  }

  refreshAfterChange() {
    if (this.showType == "Admins") {
      this.getAllAdmins();
    } else if (this.showType == "Pet Types") {
      this.getAllPetTypes();
    } else if (this.showType == "Pet Owners") {
      this.getAllPetOwners;
    } else {
      this.getAllCaretakers();
    }
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
    ref.disableClose = true;
    ref.afterClosed().subscribe(msg => {
      if (msg) {
        this.refreshAfterChange();
      };
    })
  }

  openNewAdminForm() {
    const ref = this.dialog.open(FormNewAdminComponent);
    ref.disableClose = true;
    ref.afterClosed().subscribe(msg => {
      if (msg) {
        this.refreshAfterChange();
      };
    })
  }

  openNewTypeForm() {
    const ref = this.dialog.open(FormNewPetTypeComponent);
    ref.disableClose = true;
    ref.afterClosed().subscribe(result => {
      if (result) {
       this.refreshAfterChange();
      }
    });
  }

  deleteUser(email) {
    this.pcsAdminService.deleteUser(email).subscribe(msg => {
      this.refreshAfterChange();
      this.msg = "Account successfully deleted";
    });
  }

  showHide(po) {
    if (!po.show) {
      this.pcsAdminService.getPetOwnerPets(po.email).subscribe((pets) => {
        po.pets = pets;
        po.show = true;
      });
    } else {
      po.pets = [];
      po.show = false;
    }
  }

  showDetailedPet(pet) {
    console.log(pet);
    this.dialog.open(DetailedPetComponent, { data : { 
        owner_email: pet.email,
        pet_name: pet.pet_name
      }
    });
  }
}
