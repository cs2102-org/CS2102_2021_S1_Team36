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
}
