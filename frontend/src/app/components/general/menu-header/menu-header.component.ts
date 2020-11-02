import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { AuthService } from 'src/app/services/auth/auth.service';
import { LoginComponent } from '../login/login.component';

@Component({
  selector: 'app-menu-header',
  templateUrl: './menu-header.component.html',
  styleUrls: ['./menu-header.component.css'],
})
export class MenuHeaderComponent implements OnInit {
  isLogged: boolean = false;

  constructor(
    private dialog: MatDialog,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    if (localStorage.hasOwnProperty('accessToken')) {
      this.isLogged = true;
    }
    this.authService.loginNotiService
      .subscribe(message => {
        if (message == "Login success") {
          this.isLogged=true;
        } else {
          this.isLogged=false;
        }
      });
  }

  openLogin() {
    this.dialog.open(LoginComponent);
  }

  logout() {
    this.authService.logout();
    this.router.navigateByUrl('caretaker-availabilities');
  }
}
