import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { PcsadminService } from 'src/app/services/pcsadmin/pcsadmin.service';

@Component({
  selector: 'app-form-new-admin',
  templateUrl: './form-new-admin.component.html',
  styleUrls: ['./form-new-admin.component.css']
})
export class FormNewAdminComponent implements OnInit {
  signUpForm = new FormGroup({
    name: new FormControl('', Validators.required),
    email: new FormControl('', [Validators.required, Validators.email]),
  });

  err = '';

  constructor(private dialogRef: MatDialogRef<FormNewAdminComponent>, private pcsAdminService: PcsadminService) { }

  ngOnInit(): void {
  }

  onSubmitSignUp() {
    this.pcsAdminService.postNewAdmin(this.signUpForm.value).subscribe(msg => {
      if (msg === "User successfully created.") {
        this.dialogRef.close(true);
      } else if (msg === "This email is already taken. User creation failed. ") {
        this.err = msg;
      }
    });
  }
}
