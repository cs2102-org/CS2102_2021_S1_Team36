import { Component, OnInit } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { Validators } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { AuthService } from 'src/app/services/auth/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
})
export class LoginComponent implements OnInit {
  errors: string = "";

  loginForm = new FormGroup({
    email: new FormControl('', [Validators.required, Validators.email]),
    password: new FormControl('', Validators.required),
  });

  constructor(
    private dialogRef: MatDialogRef<LoginComponent>,
    private authService: AuthService,
    private router: Router
  ) {
    this.authService.loginErrorService.subscribe(errors => {
      this.errors = errors;
    });
  }

  ngOnInit(): void {}

  onSubmit() {
    const loginDetails = this.loginForm.value;
    this.authService.login(loginDetails);
    this.authService.loginNotiService.subscribe(message => {
      this.dialogRef.close();
      if (this.router.url === '/signup') {
        this.router.navigateByUrl('caretaker-availabilities');
      }
    });
  }
}
