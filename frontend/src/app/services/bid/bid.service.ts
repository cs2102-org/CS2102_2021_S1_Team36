import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class BidService {

  constructor(private http: HttpClient) { }

  public postBid(bidDetails): Observable<any> {
    return this.http.post(baseurl + '/api/bids/add', bidDetails, getHttpOptionsWithAuth());
  }

  public getBids(): Observable<any> {
    return this.http.get(baseurl + '/api/bids/by', getHttpOptionsWithAuth());
  }

  public putBidRating(bidDetails): Observable<any> {
    return this.http.put(baseurl + '/api/bids/rate', bidDetails, getHttpOptionsWithAuth());
  }

  public getPendingBids(): Observable<any> {
    return this.http.get(baseurl + '/api/bids/by/pending', getHttpOptionsWithAuth());
  }

  public getDoneBids(): Observable<any> {
    return this.http.get(baseurl + '/api/bids/by/done', getHttpOptionsWithAuth());
  }

  public getRejectedBids(): Observable<any> {
    return this.http.get(baseurl + '/api/bids/by/rejected', getHttpOptionsWithAuth());
  }

  public getBidsCaretaker(): Observable<any> {
    return this.http.post(baseurl + '/api/bids/for', '', getHttpOptionsWithAuth());
  }

  public getPendingBidsCaretaker(): Observable<any> {
    return this.http.post(baseurl + '/api/bids/for', {'is_confirmed': "pending"}, getHttpOptionsWithAuth());
  }

  public getDoneBidsCaretaker(): Observable<any> {
    return this.http.post(baseurl + '/api/bids/for', {'is_confirmed': "done"}, getHttpOptionsWithAuth());
  }

  public getRejectedBidsCaretaker(): Observable<any> {
    return this.http.post(baseurl + '/api/bids/for', {'is_confirmed': "rejected"}, getHttpOptionsWithAuth());
  }

  public postAcceptBid(details): Observable<any> {
    return this.http.put(baseurl + '/api/bids/status', details, getHttpOptionsWithAuth());
  }

  public postRejectBid(details): Observable<any> {
    return this.http.put(baseurl + '/api/bids/status', details, getHttpOptionsWithAuth());
  }

  public getCaretakerEarnings(details): Observable<any> {
    return this.http.post(baseurl + '/api/bids/hist/range/', details, getHttpOptionsWithAuth());
  }

  public postPaidBid(details): Observable<any> {
    return this.http.put(baseurl + '/api/bids/paid', details, getHttpOptionsWithAuth());
  }
}
