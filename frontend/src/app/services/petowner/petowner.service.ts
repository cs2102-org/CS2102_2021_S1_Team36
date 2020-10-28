import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../commons.service';

@Injectable({
  providedIn: 'root'
})
export class PetownerService {

  constructor(private http: HttpClient) { }

  public getPetOwnerPets(): Observable<any> {
    return this.http.get(baseurl + '/api/petowner/pets', getHttpOptionsWithAuth());
  }

  public getPetOwnerPetsWithCaretaker(email): Observable<any> {
    return this.http.get(baseurl + '/api/petowner/pets/' + email, getHttpOptionsWithAuth());
  }

}
