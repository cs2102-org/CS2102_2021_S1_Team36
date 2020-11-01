import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class CaretakerService {

  constructor(private http: HttpClient) 
  {}

  public getActiveCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/active', httpOptions);
  }

  public getFilteredActiveCaretakers(details): Observable<any> {
    return this.http.post(baseurl + '/api/caretaker/filter/', details, httpOptions);
  }

  public getRecommendedCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/rec/', getHttpOptionsWithAuth());
  }

  public getAvailPartTimeCareTaker(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/pt/avail/' + email, httpOptions);
  }

  public getAvailFullTimeCareTaker(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/ft/na/' + email, httpOptions);
  }

   public getCareTakerPrice(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/caresfor/' + email, httpOptions);
  }

  public getCareTakerDetails(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/detailed/' + email, httpOptions);
  }

  public getAllCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/all', getHttpOptionsWithAuth());
  }
}
