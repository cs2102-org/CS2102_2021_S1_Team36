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

  public getListOfPetTypes(details): Observable<any> {
    const start = details[0];
    const end = details[1];
    return this.http.get(baseurl + '/api/pcs-admins/supplyanddemand/' + start + "/" + end, httpOptions);
  }

  public deleteUser(details): Observable<any> {
    return this.http.delete(baseurl + '/api/pcs-admins/user/' + details, httpOptions);
  }

  public deletePetType(details): Observable<any> {
    return this.http.delete(baseurl + '/api/pcs-admins/pet-type/' + details, httpOptions);
  }

  public postNewPetType(details): Observable<any> {
    return this.http.post(baseurl + '/api/pcs-admins/pet-types', details, httpOptions);
  }

   public putPetType(details): Observable<any> {
    return this.http.put(baseurl + '/api/pcs-admins/pet-types', details, httpOptions);
  }

  public getPetOwnerPets(email): Observable<any> {
    return this.http.get(baseurl + '/api/pcs-admins/pets/' + email, httpOptions);
  }

  public getAllCaretakers(details): Observable<any> {
    const start = details[0];
    const end = details[1];
    return this.http.get(baseurl + '/api/pcs-admins/salaries/' + start + "/" + end, httpOptions);
  }

  public postNewAdmin(details): Observable<any> {
    return this.http.post(baseurl + '/api/pcs-admins/', details, httpOptions);
  }

   public postNewFullTime(details): Observable<any> {
    return this.http.post(baseurl + '/api/pcs-admins/ft', details, httpOptions);
  }
}
