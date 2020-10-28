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
  signUpSuccess: Boolean = false;
  errorMessage: string = "";

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
  constructor(
    private dialog: MatDialog,
    private authService: AuthService
  ) {}

  ngOnInit(): void {}

  onSubmitSignUp() {
    const signUpDetails = this.signUpForm.value;
    this.authService.signUp(signUpDetails);
    this.authService.loginNotiService.subscribe(message => {
      if (message == "Signup success") {
        this.signUpSuccess=true;
        this.signUpForm.reset();
        this.errorMessage = "";
      }
    });
    this.authService.loginErrorService.subscribe(err => {
      if (err.indexOf("duplicate key value")) {
        this.errorMessage = "User already exists!";
      }
    });
  }
  
  openLogin() {
    this.dialog.open(LoginComponent);
  }
}
