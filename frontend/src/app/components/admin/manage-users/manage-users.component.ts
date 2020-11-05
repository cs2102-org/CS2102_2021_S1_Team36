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
  maxMonth;
  maxYear;
  month;
  date;
  year;
  monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  constructor(private caretakerService: CaretakerService, private dialog: MatDialog,
    private pcsAdminService: PcsadminService,
    private petOwnerService: PetownerService,
    private router: Router) { }

  ngOnInit(): void {
    this.getAllAdmins();
    const currDate = new Date();
    currDate.setMonth(currDate.getMonth() - 1);
    this.date = currDate;
    this.setMonthYear();
    this.maxMonth = this.date.getMonth();
    this.maxYear = this.date.getFullYear();
  }

  toggleDateLeft() {
    this.date.setMonth(this.date.getMonth() - 1);
    this.setMonthYear();
    this.getAllCaretakers();
  }

  toggleDateRight() {
    this.getCurrentRange();
    if (this.date.getMonth() == this.maxMonth && this.date.getFullYear() == this.maxYear) {

    } else {
      this.date.setMonth(this.date.getMonth() + 1);
      this.setMonthYear();
      this.getAllCaretakers();
    }
  }

  getCurrentRange() {
    const y = this.date.getFullYear(), m = this.date.getMonth();
    const firstDay = new Date(y, m, 2).toISOString().slice(0,10);
    const lastDay = new Date(y, m + 1, 1).toISOString().slice(0,10);
    return [firstDay, lastDay];
  }

  setMonthYear() {
    this.month = this.monthNames[this.date.getMonth()];
    this.year = this.date.getFullYear();
  }

  getProfit(caretaker) {
    if (caretaker.revenue == null) {
      caretaker.profit = -caretaker.getsalary;
    } else {
      caretaker.profit = caretaker.revenue - caretaker.getsalary;
    }
    return caretaker;
  }

  getAllCaretakers() {
    this.pcsAdminService.getAllCaretakers(this.getCurrentRange()).subscribe(caretakers => {
      this.showType = "Caretakers";
      this.msg = '';
      this.things = caretakers.map(this.getProfit);
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

  checkAboveZero(e) {
    return e != '-' && e > 0;
  }

  checkBelowZero(e) {
    return e != '-' && e < 0;
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
