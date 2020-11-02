import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';

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

  constructor(private dialogRef: MatDialogRef<FormNewAdminComponent>) { }

  ngOnInit(): void {
  }

  onSubmitSignUp() {

  }
}
