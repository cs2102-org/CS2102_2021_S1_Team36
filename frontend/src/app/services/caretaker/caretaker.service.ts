import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, httpOptions } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class CaretakerService {

  constructor(private http: HttpClient) 
  {}

  public getActiveCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/active', httpOptions);
  }

  public getAvailPartTimeCareTaker(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/pt/avail/' + email, httpOptions);
  }

  public getAvailFullTimeCareTaker(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/ft/na/:email', httpOptions);
  }
}
