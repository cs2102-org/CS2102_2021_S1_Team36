import { Component, OnInit } from '@angular/core';
import { ValidatorFn, FormGroup, ValidationErrors, FormControl, Validators } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { LoginComponent } from '../login/login.component';

@Component({
  selector: 'app-signup',
  templateUrl: './signup.component.html',
  styleUrls: ['./signup.component.css'],
})
export class SignupComponent implements OnInit {
  passwordMatchValidator: ValidatorFn = (
    control: FormGroup
  ): ValidationErrors | null => {
    const password = control.get('password');
    const passwordConfirm = control.get('password_confirm');
    return password && passwordConfirm &&
      password.value === passwordConfirm.value ? null : { notMatched: true };
  };

  signUpForm = new FormGroup(
    {
      name: new FormControl('', Validators.required),
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', Validators.required),
      password_confirm: new FormControl(''),
      description: new FormControl(''),
      pet_owner: new FormControl(''),
      caretaker: new FormControl(''),
      caretaker_type: new FormControl('')
    },
    { validators: this.passwordMatchValidator }
  );
  constructor(private dialog: MatDialog) {}

  ngOnInit(): void {}

  onSubmit() {
    const signUpDetails = this.signUpForm.value;
    console.log(signUpDetails);
  }
  
  openLogin() {
    this.dialog.open(LoginComponent);
  }
}
