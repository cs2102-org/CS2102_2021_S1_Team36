import { Component, OnInit } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { baseurl, getHttpOptionsWithAuth, httpOptions } from '../../../services/commons.service';
import { FormControl, FormGroup, FormBuilder } from '@angular/forms';
import { AuthService } from 'src/app/services/auth/auth.service';
import { PetownerService } from 'src/app/services/petowner/petowner.service';

@Component({
  selector: 'app-caretaker-profile',
  templateUrl: './caretaker-profile.component.html',
  styleUrls: ['./caretaker-profile.component.css']
})
export class CaretakerProfileComponent implements OnInit {

  pets;
  email;

  constructor(private http: HttpClient,
              private fb: FormBuilder,
              private authService: AuthService,
              private petOwnerService: PetownerService) { }

  profileForm = new FormGroup({
    name: new FormControl(''),
    password: new FormControl(''),
    description: new FormControl(''),
  });

  public getCaretaker(): Observable<any> {
    return this.http.get(baseurl + '/api/auth/profile', getHttpOptionsWithAuth());
  }

  // public getPetOwnerPetsWithCaretaker() {

  // }

  // getPetOwnerPets() {
  //   this.petOwnerService.getPetOwnerPetsWithCaretaker().subscribe((pets) => {
  //     this.pets = pets.reduce((accumulator, currentValue) => {
  //       accumulator[currentValue.pet_name] = currentValue.species;
  //       return accumulator;
  //     }, {});
  //   });
  // }

  ngOnInit(): void {
    console.log(this.getCaretaker());
    this.profileForm.patchValue({
      name: ['Lam'],
      description: ['Desccc'],
    })
  }

  onSubmit(profileParam): void {
    console.log('SENT');
    console.log(profileParam);
  }
}
