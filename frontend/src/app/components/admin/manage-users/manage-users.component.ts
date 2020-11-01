import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { CaretakerService } from 'src/app/services/caretaker/caretaker.service';
import { FormNewAdminComponent } from '../form-new-admin/form-new-admin.component';
import { FormNewCaretakerComponent } from '../form-new-caretaker/form-new-caretaker.component';

@Component({
  selector: 'app-manage-users',
  templateUrl: './manage-users.component.html',
  styleUrls: ['./manage-users.component.css']
})
export class ManageUsersComponent implements OnInit {
  caretakers;

  constructor(private caretakerService: CaretakerService, private dialog: MatDialog) { }

  ngOnInit(): void {
    this.getAllCaretakers();
  }

  getAllCaretakers() {
    this.caretakerService.getAllCaretakers().subscribe(caretakers => {
      this.caretakers = caretakers;
    });
  }

  openNewCaretakerForm() {
    const ref = this.dialog.open(FormNewCaretakerComponent);
    // ref.disableClose = true;
  }

  openNewAdminForm() {
    const ref = this.dialog.open(FormNewAdminComponent);
    // ref.disableClose = true;
  }
}
