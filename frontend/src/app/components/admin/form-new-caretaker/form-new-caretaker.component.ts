import { Component, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';

@Component({
  selector: 'app-form-new-caretaker',
  templateUrl: './form-new-caretaker.component.html',
  styleUrls: ['./form-new-caretaker.component.css']
})
export class FormNewCaretakerComponent implements OnInit {
  signUpForm = new FormGroup({
    name: new FormControl('', Validators.required),
    email: new FormControl('', [Validators.required, Validators.email]),
  });

  constructor(private dialogRef: MatDialogRef<FormNewCaretakerComponent>) { }

  ngOnInit(): void {
  }

  onSubmitSignUp() {

  }

}
