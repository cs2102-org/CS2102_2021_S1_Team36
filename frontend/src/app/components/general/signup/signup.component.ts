import { Component, OnInit } from '@angular/core';
import { ValidatorFn, FormGroup, ValidationErrors, FormControl, Validators } from '@angular/forms';
import { MatDialog } from '@angular/material/dialog';
import { AuthService } from 'src/app/services/auth/auth.service';
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
  message: string = "";

  signUpForm = new FormGroup(
    {
      name: new FormControl('', Validators.required),
      email: new FormControl('', [Validators.required, Validators.email]),
      password: new FormControl('', [Validators.required, Validators.minLength(4)]),
      password_confirm: new FormControl(''),
      description: new FormControl(''),
      pet_owner: new FormControl(''),
      caretaker: new FormControl(''),
    },
    { validators: this.passwordMatchValidator }
  );
  constructor(
    private dialog: MatDialog,
    private authService: AuthService
  ) {}

  ngOnInit(): void {}

  onSubmitSignUp() {
    this.message = "";
    const signUpDetails = this.signUpForm.value;
    this.authService.signUp(signUpDetails);
    this.authService.loginErrorService.subscribe(err => {
      if (err.indexOf("duplicate key value") >= 0) {
        this.message = "User already exists!";
      } else {
        this.message = err;
      }
    });
    this.authService.loginNotiService.subscribe(message => {
      if (message == "Signup success") {
        this.signUpForm.reset();
        this.message = "Signup Success. Login Now!";
      }
    });
  }
  
  openLogin() {
    this.dialog.open(LoginComponent);
  }
}
