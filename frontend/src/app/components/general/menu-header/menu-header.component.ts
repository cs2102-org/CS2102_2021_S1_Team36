import { Component, OnInit } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { AuthService } from 'src/app/services/auth/auth.service';
import { LoginComponent } from '../login/login.component';

@Component({
  selector: 'app-menu-header',
  templateUrl: './menu-header.component.html',
  styleUrls: ['./menu-header.component.css'],
})
export class MenuHeaderComponent implements OnInit {
  isLogged: boolean = false;
  isPetOwner: boolean = false;
  isCaretaker: boolean = false;
  isAdmin: boolean = false;

  constructor(
    private dialog: MatDialog,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    if (localStorage.hasOwnProperty('accessToken')) {
      this.isLogged = true;
    }
    this.authService.loginNotiService
      .subscribe(message => {
        if (message == "Login success") {
          this.isLogged=true;
          this.checkAccess();
        } else {
          this.isLogged=false;
        }
      });
    this.checkAccess();
  }

  checkAccess() {
    if (localStorage.hasOwnProperty('caretaker')) {
      this.isCaretaker = true;
    }
    if (localStorage.hasOwnProperty('petowner')) {
      this.isPetOwner = true;
    }
    if (localStorage.hasOwnProperty('admin')) {
      this.isAdmin = true;
    }
  }

  openLogin() {
    this.dialog.open(LoginComponent);
  }

  logout() {
    this.authService.logout();
    this.isCaretaker = false;
    this.isPetOwner = false;
    this.isAdmin = false;
  }
}
