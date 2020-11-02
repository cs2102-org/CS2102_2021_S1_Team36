import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';
import { baseurl, httpOptions } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private errors: string = "";
  private errorSignal = new Subject<string>();
  public loginErrorService = this.errorSignal.asObservable();
  private notiSignal = new Subject<string>();
  public loginNotiService = this.notiSignal.asObservable();

  constructor(
    private http: HttpClient) 
  {}

  public login(loginDetails): void {
    this.errors = "";
    this.http
      .post(baseurl + '/api/auth/login', loginDetails, httpOptions)
      .subscribe(
        (data) => {
          this.updateAfterLogin(data);
          this.notiSignal.next("Login success");
        },
        (err) => {
          this.errors = err['error']['error'];
          this.errorSignal.next(this.errors);
        }
      );
  }

  signUp(signUpDetails): void {
    this.errors = "";
    this.http
      .post(baseurl + '/api/auth/signup', signUpDetails, httpOptions)
      .subscribe(
        (response) => {
          this.notiSignal.next("Signup success");
        },
        (err) => {
          const error = err['error']['error'];
          this.errorSignal.next(this.errors);
        }
      );
  }

  public logout() {
    localStorage.clear();
    this.notiSignal.next("Logout");
  }

  private updateAfterLogin(data): void {
    console.log(data);
    const accessToken = data['token'];
    if (data['pemail'] != null) {
      localStorage.setItem('petowner', data['pemail']);
    }
    if (data['cemail'] != null) {
      localStorage.setItem('caretaker', data['cemail']);
    }
    if (data['aemail'] != null) {
      localStorage.setItem('admin', data['aemail']);
    }
    this.updateAccess(accessToken);
  }

   private updateAccess(token): void {
    localStorage.setItem('accessToken', token);
    this.errors = "";
  }
}
