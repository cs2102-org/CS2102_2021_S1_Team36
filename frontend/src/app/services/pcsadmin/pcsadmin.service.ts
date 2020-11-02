import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, httpOptions } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class PcsadminService {

  constructor(private http: HttpClient) { }

  public getAdminList(): Observable<any> {
    return this.http.get(baseurl + '/api/pcs-admins/admins', httpOptions);
  }

  public getListOfPetTypes(): Observable<any> {
    return this.http.get(baseurl + '/api/pcs-admins/pet-types', httpOptions);
  }
}
