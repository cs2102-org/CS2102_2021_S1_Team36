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

  public getFilteredRecommendedCaretakers(details): Observable<any> {
    return this.http.post(baseurl + '/api/caretaker/filter/recommended', details, getHttpOptionsWithAuth());
  }

  public getFilteredTransactedCaretakers(details): Observable<any> {
    return this.http.post(baseurl + '/api/caretaker/filter/transacted', details, getHttpOptionsWithAuth());
  }

  public getRecommendedCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/rec/', getHttpOptionsWithAuth());
  }

  public getTransactedCaretakers(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/txnbefore', getHttpOptionsWithAuth());
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

  public postNewLeave(details): Observable<any> {
    return this.http.post(baseurl + '/api/caretaker/ft/leave/new/range', details, getHttpOptionsWithAuth());
  }

  public getLeaveDates(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/ft/leave', getHttpOptionsWithAuth());
  }

  public getAvailDates(): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/pt/av', getHttpOptionsWithAuth());
  }

   public postNewAvail(details): Observable<any> {
    return this.http.post(baseurl + '/api/caretaker/pt/avail/new/range', details, getHttpOptionsWithAuth());
  }

  public deleteLeave(date): Observable<any> {
    return this.http.delete(baseurl + '/api/caretaker/ft/leave/' + date, getHttpOptionsWithAuth());
  }

  public deleteAvail(date): Observable<any> {
    return this.http.delete(baseurl + '/api/caretaker/pt/avail/' + date, getHttpOptionsWithAuth());
  }

  public getCaretakerReviews(email): Observable<any> {
    return this.http.get(baseurl + '/api/caretaker/reviews/' + email, httpOptions);
  }
}
