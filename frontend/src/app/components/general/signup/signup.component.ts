import { Component, OnInit } from '@angular/core';
import { ValidatorFn, FormGroup, ValidationErrors, FormControl, Validators } from '@angular/forms';

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
    },
    { validators: this.passwordMatchValidator }
  );
  constructor() {}

  ngOnInit(): void {}

  onSubmit() {
    const signUpDetails = this.signUpForm.value;
  }
}
